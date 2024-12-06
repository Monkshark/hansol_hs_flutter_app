import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hansol_high_school/API/meal_data_api.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class DailyMealNotification {
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initializeNotifications() async {
    await _initializeNotifications();
    _isInitialized = true;
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

  Future<void> scheduleDailyNotifications() async {
    if (!_isInitialized) {
      await initializeNotifications();
    }
    print('Scheduling daily notifications');

    bool isBreakfastNotificationOn = SettingData().isBreakfastNotificationOn;
    TimeOfDay breakfastTime = _parseTimeOfDay(SettingData().breakfastTime);
    bool isLunchNotificationOn = SettingData().isLunchNotificationOn;
    TimeOfDay lunchTime = _parseTimeOfDay(SettingData().lunchTime);
    bool isDinnerNotificationOn = SettingData().isDinnerNotificationOn;
    TimeOfDay dinnerTime = _parseTimeOfDay(SettingData().dinnerTime);
    await cancelAllNotifications();

    List<int> weekdays = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ];

    if (isBreakfastNotificationOn) {
      await _scheduleNotification(
        id: 1,
        mealType: MealDataApi.BREAKFAST,
        time: breakfastTime,
        weekdays: weekdays,
      );
    }

    if (isLunchNotificationOn) {
      await _scheduleNotification(
        id: 2,
        mealType: MealDataApi.LUNCH,
        time: lunchTime,
        weekdays: weekdays,
      );
    }

    if (isDinnerNotificationOn) {
      await _scheduleNotification(
        id: 3,
        mealType: MealDataApi.DINNER,
        time: dinnerTime,
        weekdays: weekdays,
      );
    }

    print('Daily notifications scheduled');
  }

  Future<void> updateNotifications() async {
    print('Updating notifications');
    await cancelAllNotifications();
    await scheduleDailyNotifications();
    print('Notifications updated');
  }

  Future<void> cancelAllNotifications() async {
    await _localNotificationsPlugin.cancelAll();
    print('All notifications cancelled');
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    final format = DateFormat.Hm();
    DateTime dateTime = format.parse(timeString);
    print('Parsed time: $timeString to ${dateTime.hour}:${dateTime.minute}');
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  Future<void> _scheduleNotification({
    required int id,
    required int mealType,
    required TimeOfDay time,
    required List<int> weekdays,
  }) async {
    for (int weekday in weekdays) {
      tz.TZDateTime scheduledDate = _nextInstanceOfWeekday(time, weekday);
      print(
          'Scheduling notification [$id] for weekday $weekday at $scheduledDate');

      String formattedDate =
          '${scheduledDate.year}/${scheduledDate.month}/${scheduledDate.day}';
      String mealTypeString;
      switch (mealType) {
        case 1:
          mealTypeString = '조식 정보';
          break;
        case 2:
          mealTypeString = '중식 정보';
          break;
        case 3:
          mealTypeString = '석식 정보';
          break;
        default:
          mealTypeString = '급식 정보';
      }

      String title = '$formattedDate $mealTypeString';
      String body = '아래로 내려서 $mealTypeString 확인';
      String bigText = (await MealDataApi.getMeal(
            date: DateTime(
                scheduledDate.year, scheduledDate.month, scheduledDate.day),
            mealType: mealType,
            type: MealDataApi.MENU,
          ))
              ?.meal ??
          '급식 정보가 없습니다';

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_meal_channel_id',
        'Daily Meal Notifications',
        channelDescription: '급식 정보 알림을 제공합니다.',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(
          bigText,
          contentTitle: title,
          summaryText: '',
        ),
        showWhen: true,
        ticker: '',
      );

      DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        subtitle: body,
      );

      NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotificationsPlugin.zonedSchedule(
        id * 10 + weekday,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(TimeOfDay time, int weekday) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    while (scheduledDate.weekday != weekday ||
        scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    print('Next instance of weekday $weekday at $scheduledDate');
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfTime(TimeOfDay timeOfDay) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      timeOfDay.hour,
      timeOfDay.minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    print(
        'Next instance of time ${timeOfDay.hour}:${timeOfDay.minute} at $scheduledDate');
    return scheduledDate;
  }
}
 