import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/API/meal_data_api.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();

  factory NotificationManager() {
    return _instance;
  }

  NotificationManager._internal();

  late bool isBreakfastNotificationOn;
  late TimeOfDay breakfastTime;
  late bool isLunchNotificationOn;
  late TimeOfDay lunchTime;
  late bool isDinnerNotificationOn;
  late TimeOfDay dinnerTime;
  late bool isNullNotificationOn;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    await SettingData().init();
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    await _loadSettings();
    await _initializeNotifications();
    await _scheduleAllMealNotifications();
    await scheduleMidnightAlarm();
  }

  Future<void> _initializeNotifications() async {
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    await _requestIOSPermissions();
  }

  Future<void> _requestIOSPermissions() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _loadSettings() async {
    isBreakfastNotificationOn = SettingData().isBreakfastNotificationOn;
    breakfastTime = _parseTimeOfDay(SettingData().breakfastTime);
    isLunchNotificationOn = SettingData().isLunchNotificationOn;
    lunchTime = _parseTimeOfDay(SettingData().lunchTime);
    isDinnerNotificationOn = SettingData().isDinnerNotificationOn;
    dinnerTime = _parseTimeOfDay(SettingData().dinnerTime);
    isNullNotificationOn = SettingData().isNullNotificationOn;
  }

  Future<void> _scheduleAllMealNotifications() async {
    DateTime now = DateTime.now();
    for (int i = 0; i < 7; i++) {
      DateTime date = now.add(Duration(days: i));
      await _scheduleMealNotificationsForDate(date);
    }
  }

  Future<void> _scheduleMealNotificationsForDate(DateTime date) async {
    if (isBreakfastNotificationOn) {
      await _scheduleMealNotification(
        date: date,
        time: breakfastTime,
        mealType: MealDataApi.BREAKFAST,
        notificationId: _getNotificationId(date, MealDataApi.BREAKFAST),
      );
    }

    if (isLunchNotificationOn) {
      await _scheduleMealNotification(
        date: date,
        time: lunchTime,
        mealType: MealDataApi.LUNCH,
        notificationId: _getNotificationId(date, MealDataApi.LUNCH),
      );
    }

    if (isDinnerNotificationOn) {
      await _scheduleMealNotification(
        date: date,
        time: dinnerTime,
        mealType: MealDataApi.DINNER,
        notificationId: _getNotificationId(date, MealDataApi.DINNER),
      );
    }
  }

  int _getNotificationId(DateTime date, int mealType) {
    String idString =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}$mealType';
    return int.parse(idString);
  }

  Future<void> _scheduleMealNotification({
    required DateTime date,
    required TimeOfDay time,
    required int mealType,
    required int notificationId,
  }) async {
    final DateTime scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      scheduledDateTime,
      tz.local,
    );

    String mealMenu = (await MealDataApi.getMeal(
      date: date,
      mealType: mealType,
      type: '메뉴',
    ))
        .toString();

    String notificationTitle =
        "${date.month}/${date.day} ${_getMealName(mealType)} 정보";

    if (_shouldScheduleNotification(mealMenu, isNullNotificationOn) &&
        !_isWeekend(date)) {
      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails();

      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(iOS: iOSPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        notificationTitle,
        mealMenu,
        scheduledDate,
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );

      log("Scheduled $notificationTitle notification for ${time.hour}:${time.minute} with menu: $mealMenu");
    } else {
      log('식단 정보가 없거나 알림 설정이 꺼져 있거나 주말입니다.');
    }
  }

  String _getMealName(int mealType) {
    switch (mealType) {
      case 1:
        return '조식';
      case 2:
        return '중식';
      case 3:
        return '석식';
      default:
        return '';
    }
  }

  Future<void> updateNotifications() async {
    await _loadSettings();
    await _scheduleAllMealNotifications();
  }

  static TimeOfDay _parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      final hourPart = parts[0];
      final minutePart = parts[1];
      if (minutePart.contains(' ')) {
        final minuteParts = minutePart.split(' ');
        final minute = int.parse(minuteParts[0]);
        final period = minuteParts[1];
        int hour = int.parse(hourPart);
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final hour = int.parse(hourPart);
        final minute = int.parse(minutePart);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      return const TimeOfDay(hour: 6, minute: 0);
    }
  }

  bool _isWeekend(DateTime date) {
    return (date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday);
  }

  bool _shouldScheduleNotification(String mealMenu, bool isNullNotificationOn) {
    return mealMenu != '급식 정보가 없습니다.' ||
        (isNullNotificationOn && mealMenu == '급식 정보가 없습니다.');
  }

  Future<void> scheduleMidnightAlarm() async {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);

    await AndroidAlarmManager.cancel(0);

    await AndroidAlarmManager.oneShotAt(
      midnight,
      0,
      midnightCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}

void midnightCallback() {
  WidgetsFlutterBinding.ensureInitialized();
  final notificationManager = NotificationManager();
  notificationManager.updateNotifications();
}
