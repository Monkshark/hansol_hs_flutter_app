import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hansol_high_school/API/meal_data_api.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:timezone/data/latest.dart' as tz;

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

  static const MethodChannel platform =
      MethodChannel('com.example.hansol_high_school/alarm');

  Future<void> init() async {
    await SettingData().init();
    tz.initializeTimeZones();

    await _loadSettings();
    await _scheduleAllMealNotifications();
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
    await _scheduleMealNotification(
      isNotificationOn: isBreakfastNotificationOn,
      time: breakfastTime,
      mealType: MealDataApi.BREAKFAST,
      notificationTitle: "${DateTime.now().month}/${DateTime.now().day} 조식 정보",
    );
    await _scheduleMealNotification(
      isNotificationOn: isLunchNotificationOn,
      time: lunchTime,
      mealType: MealDataApi.LUNCH,
      notificationTitle: "${DateTime.now().month}/${DateTime.now().day} 중식 정보",
    );
    await _scheduleMealNotification(
      isNotificationOn: isDinnerNotificationOn,
      time: dinnerTime,
      mealType: MealDataApi.DINNER,
      notificationTitle: "${DateTime.now().month}/${DateTime.now().day} 석식 정보",
    );
  }

  Future<void> _scheduleMealNotification({
    required bool isNotificationOn,
    required TimeOfDay time,
    required int mealType,
    required String notificationTitle,
  }) async {
    if (!isNotificationOn) {
      await _cancelNotification(notificationTitle);
      return;
    }

    final now = DateTime.now();
    final notificationDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);

    if (notificationDate.isBefore(now)) {
      notificationDate.add(Duration(days: 1));
    }

    final String mealMenu = (await MealDataApi.getMeal(
      date: DateTime.now(),
      mealType: mealType,
      type: '메뉴',
    ))
        .toString();

    if (getMealSetting(mealMenu, isNullNotificationOn) && !isWeekend()) {
      try {
        await platform.invokeMethod('scheduleMealNotification', {
          'hour': time.hour.toString(),
          'minute': time.minute.toString(),
          'notificationTitle': notificationTitle,
          'mealMenu': mealMenu,
        });
        log("Scheduled $notificationTitle notification for ${time.hour}:${time.minute} with menu: $mealMenu");
      } catch (e) {
        log("Failed to schedule notification: $e");
      }
    } else {
      log('Meal is null or null notifications are disabled or today is weekend');
    }
  }

  Future<void> _cancelNotification(String notificationTitle) async {
    try {
      await platform.invokeMethod('cancelMealNotification', {
        'notificationTitle': notificationTitle,
      });
      log("Cancelled $notificationTitle notification");
    } on PlatformException catch (e) {
      log("Failed to cancel notification: '${e.message}'.");
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

  static bool isWeekend() {
    return (DateTime.now().weekday != DateTime.saturday &&
        DateTime.now().weekday != DateTime.sunday);
  }

  static bool getMealSetting(var mealMenu, var isNullNotificationOn) {
    return mealMenu != '급식 정보가 없습니다.' ||
        (isNullNotificationOn && mealMenu == '급식 정보가 없습니다.');
  }
}
