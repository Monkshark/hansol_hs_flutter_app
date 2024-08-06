import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:hansol_high_school/API/meal_data_api.dart';

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

    isBreakfastNotificationOn = SettingData().isBreakfastNotificationOn;
    breakfastTime = _parseTimeOfDay(SettingData().breakfastTime);
    isLunchNotificationOn = SettingData().isLunchNotificationOn;
    lunchTime = _parseTimeOfDay(SettingData().lunchTime);
    isDinnerNotificationOn = SettingData().isDinnerNotificationOn;
    dinnerTime = _parseTimeOfDay(SettingData().dinnerTime);
    isNullNotificationOn = SettingData().isNullNotificationOn;

    final String breakfastMenu = (await MealDataApi.getMeal(
            date: DateTime.now(), mealType: MealDataApi.BREAKFAST, type: '메뉴'))
        .toString();
    if (isBreakfastNotificationOn) {
      await scheduleMealNotification(
        hour: breakfastTime.hour,
        minute: breakfastTime.minute,
        notificationTitle:
            "${DateTime.now().month}/${DateTime.now().day} 조식 정보",
        mealMenu: breakfastMenu,
      );
    }

    final String lunchMenu = (await MealDataApi.getMeal(
            date: DateTime.now(), mealType: MealDataApi.LUNCH, type: '메뉴'))
        .toString();
    if (isLunchNotificationOn) {
      await scheduleMealNotification(
        hour: lunchTime.hour,
        minute: lunchTime.minute,
        notificationTitle:
            "${DateTime.now().month}/${DateTime.now().day} 중식 정보",
        mealMenu: lunchMenu,
      );
    }

    final String dinnerMenu = (await MealDataApi.getMeal(
            date: DateTime.now(), mealType: MealDataApi.DINNER, type: '메뉴'))
        .toString();
    if (isDinnerNotificationOn) {
      await scheduleMealNotification(
        hour: dinnerTime.hour,
        minute: dinnerTime.minute,
        notificationTitle:
            "${DateTime.now().month}/${DateTime.now().day} 석식 정보",
        mealMenu: dinnerMenu,
      );
    }
  }

  Future<void> scheduleMealNotification({
    required int hour,
    required int minute,
    required String notificationTitle,
    required String mealMenu,
  }) async {
    try {
      if (mealMenu != '급식 정보가 없습니다.' && !isNullNotificationOn) {
        await platform.invokeMethod('scheduleMealNotification', {
          'hour': hour,
          'minute': minute,
          'notificationTitle': notificationTitle,
          'mealMenu': mealMenu,
        });
        log("Scheduled $notificationTitle notification for $hour:$minute with menu: $mealMenu");
      } else {
        log('meal is null');
      }
    } on PlatformException catch (e) {
      log("Failed to schedule notification: '${e.message}'.");
    }
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
}
