import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:hansol_high_school/API/meal_data_api.dart';

class NotificationManager {
  NotificationManager._();

  static const MethodChannel platform =
      MethodChannel('com.example.hansol_high_school/alarm');

  static Future<void> init() async {
    tz.initializeTimeZones();

    final String breakfastMenu = (await MealDataApi.getMeal(
            date: DateTime.now(), mealType: MealDataApi.BREAKFAST, type: '메뉴'))
        .toString();
    await scheduleMealNotification(
      hour: 6,
      minute: 30,
      notificationTitle: "${DateTime.now().month}/${DateTime.now().day} 조식 정보",
      mealMenu: breakfastMenu,
    );

    final String lunchMenu = (await MealDataApi.getMeal(
            date: DateTime.now(), mealType: MealDataApi.LUNCH, type: '메뉴'))
        .toString();
    await scheduleMealNotification(
      hour: 12,
      minute: 00,
      notificationTitle: "${DateTime.now().month}/${DateTime.now().day} 중식 정보",
      mealMenu: lunchMenu,
    );

    final String dinnerMenu = (await MealDataApi.getMeal(
            date: DateTime.now(), mealType: MealDataApi.DINNER, type: '메뉴'))
        .toString();
    await scheduleMealNotification(
      hour: 17,
      minute: 00,
      notificationTitle: "${DateTime.now().month}/${DateTime.now().day} 석식 정보",
      mealMenu: dinnerMenu,
    );
  }

  static Future<void> scheduleMealNotification({
    required int hour,
    required int minute,
    required String notificationTitle,
    required String mealMenu,
  }) async {
    try {
      if (mealMenu != '급식 정보가 없습니다.') {
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
}
