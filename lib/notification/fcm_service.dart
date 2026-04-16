import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/main.dart' show onNotificationTap, rootNavigatorKey;
import 'package:hansol_high_school/screens/board/admin_screen.dart';
import 'package:hansol_high_school/screens/board/notification_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_room_screen.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static StreamSubscription<String>? _tokenRefreshSub;
  static StreamSubscription<RemoteMessage>? _onMessageSub;
  static StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  static late AndroidNotificationChannel _channel;

  static Future<void> _initChannel() async {
    final l = await AppLocalizations.delegate.load(const Locale('ko'));
    _channel = AndroidNotificationChannel(
      'board_channel',
      l.noti_boardChannelName,
      description: l.noti_boardChannelDesc,
      importance: Importance.high,
    );
  }

  static Future<void> initialize() async {
    await _initChannel();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _saveToken();
    _tokenRefreshSub = _messaging.onTokenRefresh.listen(_onTokenRefresh);

    await _subscribeTopics();

    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    log('FcmService: initialized');
  }

  static Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
    await _onMessageSub?.cancel();
    await _onMessageOpenedSub?.cancel();
  }

  static Future<void> _saveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));

    log('FcmService: token saved');
  }

  static Future<void> _onTokenRefresh(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  static const boardCategories = BoardCategories.writeKeys;

  static const _categoryTopicKey = BoardCategories.topicKey;

  static String _topicName(String category) =>
      'board_${_categoryTopicKey[category] ?? category}';

  static Future<void> _subscribeTopics() async {
    if (SettingData().isBoardNotificationOn) {
      await _messaging.subscribeToTopic('board_new_post');
      log('FcmService: subscribed to board_new_post');
    }
    for (final cat in boardCategories) {
      final key = 'noti_board_$cat';
      if (SettingData().getBool(key, defaultValue: true)) {
        await _messaging.subscribeToTopic(_topicName(cat));
      }
    }
    if (SettingData().getBool('noti_board_popular', defaultValue: true)) {
      await _messaging.subscribeToTopic('board_popular');
    }
  }

  static Future<void> toggleBoardNotification(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('board_new_post');
    } else {
      await _messaging.unsubscribeFromTopic('board_new_post');
    }
    SettingData().isBoardNotificationOn = enabled;
  }

  static Future<void> toggleCategoryNotification(String category, bool enabled) async {
    final topic = _topicName(category);
    if (enabled) {
      await _messaging.subscribeToTopic(topic);
    } else {
      await _messaging.unsubscribeFromTopic(topic);
    }
    SettingData().setBool('noti_board_$category', enabled);
  }

  static Future<void> togglePopularNotification(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('board_popular');
    } else {
      await _messaging.unsubscribeFromTopic('board_popular');
    }
    SettingData().setBool('noti_board_popular', enabled);
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    final payload = _encodePayload(message.data);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    log('FcmService: opened from notification, data=${message.data}');
    _handleDeepLink(message.data);
  }

  static Future<void> _handleDeepLink(Map<String, dynamic> data) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return;

    final type = data['type']?.toString();
    try {
      switch (type) {
        case 'comment':
        case 'new_post':
          final postId = data['postId']?.toString();
          if (postId == null || postId.isEmpty) return;
          navigator.push(MaterialPageRoute(
            builder: (_) => PostDetailScreen(postId: postId),
          ));
          break;
        case 'account':
          final isManager = AuthService.cachedProfile?.isManager ?? false;
          if (isManager) {
            navigator.push(MaterialPageRoute(
              builder: (_) => const AdminScreen(),
            ));
          } else {
            navigator.push(MaterialPageRoute(
              builder: (_) => const NotificationScreen(),
            ));
          }
          break;
        case 'chat':
          final chatId = data['chatId']?.toString();
          if (chatId == null || chatId.isEmpty) return;
          final myUid = FirebaseAuth.instance.currentUser?.uid;
          if (myUid == null) return;
          final doc = await FirebaseFirestore.instance
              .collection('chats').doc(chatId).get();
          if (!doc.exists) return;
          final chatData = doc.data();
          if (chatData == null) return;
          final participants = List<String>.from(chatData['participants'] ?? []);
          final otherUid = participants.firstWhere(
            (uid) => uid != myUid,
            orElse: () => '',
          );
          if (otherUid.isEmpty) return;
          final userDoc = await FirebaseFirestore.instance
              .collection('users').doc(otherUid).get();
          final l = await AppLocalizations.delegate.load(const Locale('ko'));
          final otherName = userDoc.data()?['name']?.toString() ?? l.common_chatPartner;
          navigator.push(MaterialPageRoute(
            builder: (_) => ChatRoomScreen(
              chatId: chatId, otherUid: otherUid, otherName: otherName,
            ),
          ));
          break;
      }
    } catch (e) {
      log('FcmService: deep link error: $e');
    }
  }

  static String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(';');
  }

  static Map<String, dynamic> decodePayload(String payload) {
    final map = <String, dynamic>{};
    for (final pair in payload.split(';')) {
      final idx = pair.indexOf('=');
      if (idx > 0) {
        map[pair.substring(0, idx)] = pair.substring(idx + 1);
      }
    }
    return map;
  }

  static void handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty) return;
    _handleDeepLink(decodePayload(payload));
  }

  static Future<void> onUserLogin() async {
    await _saveToken();
    await _subscribeTopics();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}
