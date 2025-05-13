import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class DailyAlarmNotification {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    await _initializeNotifications();
    print('Notifications initialized');
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onSelectNotification,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
    );

    await _requestPermissions();
    print('Initialization complete');
  }

  void _onSelectNotification(NotificationResponse response) {
    print('Notification clicked: ${response.payload}');
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotification(NotificationResponse response) {
    print('Background notification clicked: ${response.payload}');
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _localNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      bool? granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      print('Permissions requested: $granted');

      if (granted == false) {
        print('알림 권한이 허용되지 않았습니다.');
      }
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        print('Notification permission granted.');
      } else {
        print('Notification permission denied.');
      }
    }
  }
}
