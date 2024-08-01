// notification_manager.dart
import 'dart:developer';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:hansol_high_school/API/meal_data_api.dart';

class NotificationManager {
  NotificationManager._();

  static const MethodChannel platform = MethodChannel('com.example.hansol_high_school/alarm');

  static Future<void> init() async {
    tz.initializeTimeZones();

    final String breakfastMenu = (await MealDataApi.getMeal(
        date: DateTime.now(), mealType: MealDataApi.BREAKFAST, type: '메뉴')).toString();
    await scheduleMealNotification(
      hour: 6,
      minute: 30,
      mealType: "조식",
      mealMenu: breakfastMenu,
    );

    final String lunchMenu = (await MealDataApi.getMeal(
        date: DateTime.now(), mealType: MealDataApi.LUNCH, type: '메뉴')).toString();
    await scheduleMealNotification(
      hour: 12,
      minute: 00,
      mealType: "중식",
      mealMenu: lunchMenu,
    );

    final String dinnerMenu = (await MealDataApi.getMeal(
        date: DateTime.now(), mealType: MealDataApi.DINNER, type: '메뉴')).toString();
    await scheduleMealNotification(
      hour: 17,
      minute: 00,
      mealType: "석식",
      mealMenu: dinnerMenu,
    );
  }

  static Future<void> scheduleMealNotification({
    required int hour,
    required int minute,
    required String mealType,
    required String mealMenu,
  }) async {
    try {
      await platform.invokeMethod('scheduleMealNotification', {
        'hour': hour,
        'minute': minute,
        'mealType': mealType,
        'mealMenu': mealMenu,
      });
      log("Scheduled $mealType notification for $hour:$minute with menu: $mealMenu");
    } on PlatformException catch (e) {
      log("Failed to schedule notification: '${e.message}'.");
    }
  }
}
