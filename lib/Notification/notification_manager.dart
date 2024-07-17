import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:hansol_high_school/API/meal_data_api.dart';

class NotificationManager {
  NotificationManager._();

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await createNotificationChannel();
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidInitializationSettings =
    AndroidInitializationSettings('mipmap/ic_launcher');

    const DarwinInitializationSettings darwinInitializationSettings =
    DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    requestNotificationPermissions();

    final String breakfastMenu = (await MealDataApi.getMeal(
        date: DateTime.now(), mealType: MealDataApi.BREAKFAST, type: '메뉴'))
        .toString();
    await scheduleWeeklyNotification(
      notificationId: 1,
      title: "조식",
      body: "아래로 당겨서 조식메뉴 확인",
      bigText: breakfastMenu,
      hour: 6,
      minute: 30,
      days: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday],
    );

    final String lunchMenu = (await MealDataApi.getMeal(
        date: DateTime.now(), mealType: MealDataApi.LUNCH, type: '메뉴'))
        .toString();
    await scheduleWeeklyNotification(
      notificationId: 2,
      title: "중식",
      body: "아래로 당겨서 중식메뉴 확인",
      bigText: lunchMenu,
      hour: 12,
      minute: 0,
      days: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday],
    );

    final String dinnerMenu = (await MealDataApi.getMeal(
        date: DateTime.now(), mealType: MealDataApi.DINNER, type: '메뉴'))
        .toString();
    await scheduleWeeklyNotification(
      notificationId: 3,
      title: "석식",
      body: "아래로 당겨서 석식메뉴 확인",
      bigText: dinnerMenu,
      hour: 17,
      minute: 00,
      days: [DateTime.monday, DateTime.tuesday, DateTime.wednesday, DateTime.thursday, DateTime.friday],
    );
  }

  static void requestNotificationPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> scheduleWeeklyNotification({
    required int notificationId,
    required String title,
    required String body,
    required String bigText,
    required int hour,
    required int minute,
    required List<int> days,
  }) async {
    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'channelId',
      '급식 정보 알림',
      channelDescription: '조식, 중식, 석식 메뉴를 알림으로 발송합니다.',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: false,
      styleInformation: BigTextStyleInformation(bigText),
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: const DarwinNotificationDetails(badgeNumber: 1),
    );

    for (var day in days) {
      final tz.TZDateTime scheduledTime = _nextInstanceOfWeekdayTime(hour, minute, day);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId + day,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
      log('Scheduled $title notification for day $day at $hour:$minute (Scheduled time: $scheduledTime)');
    }
  }


  static tz.TZDateTime _nextInstanceOfWeekdayTime(int hour, int minute, int day) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    log('Next instance for day $day at $hour:$minute is $scheduledDate');
    return scheduledDate;
  }


  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel androidNotificationChannel =
    AndroidNotificationChannel(
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
