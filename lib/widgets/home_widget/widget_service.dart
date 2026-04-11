import 'dart:developer';
import 'dart:ui';

import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  await WidgetService.initialize();
  await WidgetService.updateAll();
}

class WidgetService {
  static const _appGroupId = 'group.com.monkshark.hansol_high_school';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  static Future<AppLocalizations> _getLocalizations() async {
    return await AppLocalizations.delegate.load(const Locale('ko'));
  }

  static Future<void> updateAll() async {
    await Future.wait([
      updateMealWidget(),
      updateTimetableWidget(),
    ]);
  }

  static Future<void> updateMealWidget() async {
    try {
      final now = DateTime.now();
      final l = await _getLocalizations();
      final dateStr = DateFormat('M월 d일 (E)', 'ko').format(now);

      final meals = await Future.wait([
        MealDataApi.getMeal(date: now, mealType: MealDataApi.BREAKFAST, type: MealDataApi.MENU),
        MealDataApi.getMeal(date: now, mealType: MealDataApi.LUNCH, type: MealDataApi.MENU),
        MealDataApi.getMeal(date: now, mealType: MealDataApi.DINNER, type: MealDataApi.MENU),
      ]);

      final breakfast = _cleanMealText(meals[0]?.meal, l);
      final lunch = _cleanMealText(meals[1]?.meal, l);
      final dinner = _cleanMealText(meals[2]?.meal, l);

      await HomeWidget.saveWidgetData<String>('meal_date', dateStr);
      await HomeWidget.saveWidgetData<String>('meal_breakfast', breakfast);
      await HomeWidget.saveWidgetData<String>('meal_lunch', lunch);
      await HomeWidget.saveWidgetData<String>('meal_dinner', dinner);
      await HomeWidget.updateWidget(androidName: 'MealWidgetProvider');
      await HomeWidget.updateWidget(androidName: 'CombinedWidgetProvider');

      log('WidgetService: meal widget updated');
    } catch (e) {
      log('WidgetService: meal widget error: $e');
    }
  }

  static Future<void> updateTimetableWidget() async {
    try {
      final now = DateTime.now();
      final grade = SettingData().grade;
      final classNum = SettingData().classNum;

      if (grade == 0 || classNum == 0) {
        await HomeWidget.saveWidgetData<String>('timetable_data', '');
        final l = await _getLocalizations();
        await HomeWidget.saveWidgetData<String>('timetable_date', l.widget_timetableNotSet);
        await HomeWidget.updateWidget(androidName: 'TimetableWidgetProvider');
        return;
      }

      final dateStr = DateFormat('M월 d일 (E)', 'ko').format(now);

      final prefs = await SharedPreferences.getInstance();
      final gridData = prefs.getStringList('widget_timetable_grid');

      final subjects = <String>[];
      if (gridData != null && gridData.isNotEmpty) {
        final weekday = now.weekday;
        if (weekday >= 1 && weekday <= 5 && weekday - 1 < gridData.length) {
          final daySubjects = gridData[weekday - 1].split(',');
          subjects.addAll(daySubjects);
        }
      }
      while (subjects.isNotEmpty && subjects.last.isEmpty) {
        subjects.removeLast();
      }

      await HomeWidget.saveWidgetData<String>('timetable_date', dateStr);
      await HomeWidget.saveWidgetData<String>('timetable_data', subjects.join(','));
      await HomeWidget.saveWidgetData<int>('timetable_current', _getCurrentPeriod(now));
      await HomeWidget.updateWidget(androidName: 'TimetableWidgetProvider');
      await HomeWidget.updateWidget(androidName: 'CombinedWidgetProvider');

      log('WidgetService: timetable widget updated - ${subjects.length} periods: ${subjects.join(", ")}');
    } catch (e) {
      log('WidgetService: timetable widget error: $e');
    }
  }

  static String _cleanMealText(String? text, AppLocalizations l) {
    if (text == null || text.isEmpty) {
      return l.widget_noMealInfo;
    }
    return text.replaceAll(RegExp(r'\s*\([\d.]+\)'), '').replaceAll(RegExp(r'\s*<[\d.]+>'), '');
  }

  static int _getCurrentPeriod(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    const starts = [500, 560, 620, 680, 750, 810, 870];
    const ends = [550, 610, 670, 740, 800, 860, 920];

    for (int i = 0; i < starts.length; i++) {
      if (minutes >= starts[i] && minutes < ends[i]) return i + 1;
    }
    if (minutes >= ends.last) return -1;
    return 0;
  }
}
