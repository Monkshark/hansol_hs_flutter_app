import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:hansol_high_school/API/MealDataApi.dart';

class NotificationManager {
  NotificationManager._();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static init() async {
    createNotificationChannel();
    tz.initializeTimeZones();

    AndroidInitializationSettings androidInitializationSettings =
        const AndroidInitializationSettings('mipmap/ic_launcher');

    DarwinInitializationSettings darwinInitializationSettings =
        const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    requestNotificationPermissions();

    await scheduleDailyNotification(
      scheduledNotificationDateTime: tz.TZDateTime(
        tz.local,
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        6,
        00,
      ),
      title: "조식",
      body: "아래로 당겨서 조식메뉴 확인",
      bigText: (
        await MealDataApi.getMeal(
            date: DateFormat('yyyyMMdd').format(DateTime.now()),
            mealType: MealDataApi.BREAKFAST,
            type: '메뉴'),
      ).toString(),
      hour: 6,
      minute: 0,
    );
    await scheduleDailyNotification(
      scheduledNotificationDateTime: tz.TZDateTime(
        tz.local,
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        12,
        00,
      ),
      title: "중식",
      body: "아래로 당겨서 중식메뉴 확인",
      bigText: (
        await MealDataApi.getMeal(
            date: DateFormat('yyyyMMdd').format(DateTime.now()),
            mealType: MealDataApi.LUNCH,
            type: '메뉴'),
      ).toString(),
      hour: 12,
      minute: 0,
    );
    await scheduleDailyNotification(
      scheduledNotificationDateTime: tz.TZDateTime(
        tz.local,
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        17,
        00,
      ),
      title: "석식",
      body: "아래로 당겨서 석식메뉴 확인",
      bigText: (
        await MealDataApi.getMeal(
            date: DateFormat('yyyyMMdd').format(DateTime.now()),
            mealType: MealDataApi.DINNER,
            type: '메뉴'),
      ).toString(),
      hour: 17,
      minute: 00,
    );
  }

  static requestNotificationPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static Future<void> scheduleDailyNotification({
    required String title,
    required String body,
    required String bigText,
    required int hour,
    required int minute,
    required DateTime scheduledNotificationDateTime,
  }) async {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channelId',
      '급식 정보 알림',
      channelDescription: '조식, 중식, 석식 메뉴를 알림으로 발송합니다.',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: false,
      styleInformation: BigTextStyleInformation(bigText),
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(badgeNumber: 1),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      tz.TZDateTime.now(tz.local)
          .add(const Duration(days: 1))
          .subtract(Duration(hours: tz.TZDateTime.now(tz.local).hour - hour)),
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static createNotificationChannel() async {
    AndroidNotificationChannel androidNotificationChannel =
        const AndroidNotificationChannel(
      'channelId',
      '급식 정보 알림',
      description: '조식, 중식, 석식 메뉴를 알림으로 발송합니다.',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);
  }
}
