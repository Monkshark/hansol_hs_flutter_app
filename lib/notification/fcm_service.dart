import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/main.dart' show rootNavigatorKey;
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_room_screen.dart';

/// FCM(Firebase Cloud Messaging) 서비스
/// - FCM 초기화 및 알림 권한 요청
/// - Firestore에 FCM 토큰 저장 및 갱신 리스너 등록
/// - board_new_post 토픽 구독/해제로 게시판 알림 제어
/// - 포그라운드 메시지 수신 시 로컬 알림으로 표시
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'board_channel',
    '게시판 알림',
    description: '새 댓글, 게시글 알림',
    importance: Importance.high,
  );

  static Future<void> initialize() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _saveToken();
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    await _subscribeTopics();

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    log('FcmService: initialized');
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

  static Future<void> _subscribeTopics() async {
    if (SettingData().isBoardNotificationOn) {
      await _messaging.subscribeToTopic('board_new_post');
      log('FcmService: subscribed to board_new_post');
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

  /// 푸시 알림 data payload 기반 딥링크 라우팅
  /// - type=comment / new_post → 게시글 상세
  /// - type=chat → 채팅방 (chat 문서에서 상대 정보 로드)
  /// - type=account → 무시 (앱만 열림)
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
          final otherName = userDoc.data()?['name']?.toString() ?? '대화상대';
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

  /// 포그라운드 로컬 알림용 payload 인코딩 (key=value;key=value)
  static String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(';');
  }

  /// 로컬 알림 payload → Map 디코딩
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

  /// 로컬 알림(포그라운드) 탭 시 호출
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
