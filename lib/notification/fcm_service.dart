import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/data/setting_data.dart';

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

  /// 앱 시작 시 호출
  static Future<void> initialize() async {
    // 알림 채널 생성
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // FCM 권한 요청
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 포그라운드 알림 표시 설정
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM 토큰 저장
    await _saveToken();
    _messaging.onTokenRefresh.listen(_onTokenRefresh);

    // 토픽 구독
    await _subscribeTopics();

    // 포그라운드 메시지 핸들러
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // 백그라운드에서 알림 탭 시
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenedApp);

    // 앱 종료 상태에서 알림으로 열었을 때
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _onMessageOpenedApp(initialMessage);
    }

    log('FcmService: initialized');
  }

  /// FCM 토큰을 Firestore에 저장
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

  /// 토픽 구독
  static Future<void> _subscribeTopics() async {
    if (SettingData().isBoardNotificationOn) {
      await _messaging.subscribeToTopic('board_new_post');
      log('FcmService: subscribed to board_new_post');
    }
  }

  /// 게시판 알림 토글
  static Future<void> toggleBoardNotification(bool enabled) async {
    if (enabled) {
      await _messaging.subscribeToTopic('board_new_post');
    } else {
      await _messaging.unsubscribeFromTopic('board_new_post');
    }
    SettingData().isBoardNotificationOn = enabled;
  }

  /// 포그라운드에서 메시지 수신 시 로컬 알림 표시
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

  /// 알림 탭으로 앱 열었을 때
  static void _onMessageOpenedApp(RemoteMessage message) {
    // postId가 있으면 해당 글 상세로 이동할 수 있음
    // 지금은 로그만
    log('FcmService: opened from notification, data=${message.data}');
  }

  /// 로그인 후 토큰 갱신
  static Future<void> onUserLogin() async {
    await _saveToken();
    await _subscribeTopics();
  }
}

/// 백그라운드 메시지 핸들러 (top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드에서는 별도 처리 불필요 (시스템이 알림 표시)
}
