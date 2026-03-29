import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/data/setting_data.dart';

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
      payload: message.data['postId'],
    );
  }

  static void _onMessageOpenedApp(RemoteMessage message) {
    log('FcmService: opened from notification, data=${message.data}');
  }

  static Future<void> onUserLogin() async {
    await _saveToken();
    await _subscribeTopics();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}
