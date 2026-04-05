import 'dart:developer';

import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 백그라운드에서 위젯 데이터 갱신 (자정 알람에서 호출)
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  await WidgetService.initialize();
  await WidgetService.updateAll();
}

/// 홈 화면 위젯 데이터 갱신 서비스
///
/// - 급식/시간표 데이터를 SharedPreferences에 저장
/// - Android/iOS 홈 위젯에 데이터 전달
class WidgetService {
  static const _appGroupId = 'group.com.monkshark.hansol_high_school';

  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(_appGroupId);
  }

  /// 급식 + 시간표 위젯 데이터 모두 갱신
  static Future<void> updateAll() async {
    await Future.wait([
      updateMealWidget(),
      updateTimetableWidget(),
    ]);
  }

  /// 급식 위젯 데이터 갱신
  static Future<void> updateMealWidget() async {
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('M월 d일 (E)', 'ko').format(now);

      final meals = await Future.wait([
        MealDataApi.getMeal(date: now, mealType: MealDataApi.BREAKFAST, type: MealDataApi.MENU),
        MealDataApi.getMeal(date: now, mealType: MealDataApi.LUNCH, type: MealDataApi.MENU),
        MealDataApi.getMeal(date: now, mealType: MealDataApi.DINNER, type: MealDataApi.MENU),
      ]);

      final breakfast = _cleanMealText(meals[0]?.meal);
      final lunch = _cleanMealText(meals[1]?.meal);
      final dinner = _cleanMealText(meals[2]?.meal);

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

  /// 시간표 위젯 데이터 갱신
  static Future<void> updateTimetableWidget() async {
    try {
      final now = DateTime.now();
      final grade = SettingData().grade;
      final classNum = SettingData().classNum;

      if (grade == 0 || classNum == 0) {
        await HomeWidget.saveWidgetData<String>('timetable_data', '');
        await HomeWidget.saveWidgetData<String>('timetable_date', '학년/반을 설정해주세요');
        await HomeWidget.updateWidget(androidName: 'TimetableWidgetProvider');
        return;
      }

      final dateStr = DateFormat('M월 d일 (E)', 'ko').format(now);

      // 앱 시간표 화면에서 저장한 그리드 읽기
      final prefs = await SharedPreferences.getInstance();
      final gridData = prefs.getStringList('widget_timetable_grid');

      final subjects = <String>[];
      if (gridData != null && gridData.isNotEmpty) {
        final weekday = now.weekday; // 1=월 ~ 5=금
        if (weekday >= 1 && weekday <= 5 && weekday - 1 < gridData.length) {
          final daySubjects = gridData[weekday - 1].split(',');
          subjects.addAll(daySubjects);
        }
      }
      // 뒤에서부터 빈 교시 제거
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

  static String _cleanMealText(String? text) {
    if (text == null || text.isEmpty || text.contains('급식 정보가 없습니다') || text.contains('인터넷')) {
      return '정보 없음';
    }
    // 알레르기 정보 번호 제거 (예: "치킨까스 (1.2.5.6)" → "치킨까스")
    return text.replaceAll(RegExp(r'\s*\([\d.]+\)'), '').replaceAll(RegExp(r'\s*<[\d.]+>'), '');
  }

  /// 현재 교시 계산 (0 = 수업 전, -1 = 수업 끝)
  static int _getCurrentPeriod(DateTime now) {
    final minutes = now.hour * 60 + now.minute;
    // 1교시 08:20~09:10, 2교시 09:20~10:10, ...
    const starts = [500, 560, 620, 680, 750, 810, 870];
    const ends = [550, 610, 670, 740, 800, 860, 920];

    for (int i = 0; i < starts.length; i++) {
      if (minutes >= starts[i] && minutes < ends[i]) return i + 1;
    }
    if (minutes >= ends.last) return -1;
    return 0;
  }
}
