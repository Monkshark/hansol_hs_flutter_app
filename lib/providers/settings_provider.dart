import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/setting_data.dart';


class GradeClassState {
  final int grade;
  final int classNum;
  const GradeClassState({required this.grade, required this.classNum});

  bool get isSet => grade > 0 && classNum > 0;

  GradeClassState copyWith({int? grade, int? classNum}) =>
      GradeClassState(grade: grade ?? this.grade, classNum: classNum ?? this.classNum);
}

class GradeClassNotifier extends Notifier<GradeClassState> {
  @override
  GradeClassState build() => GradeClassState(
        grade: SettingData().grade,
        classNum: SettingData().classNum,
      );

  void setGrade(int grade) {
    SettingData().grade = grade;
    state = state.copyWith(grade: grade);
  }

  void setClassNum(int classNum) {
    SettingData().classNum = classNum;
    state = state.copyWith(classNum: classNum);
  }

  void setBoth(int grade, int classNum) {
    SettingData().grade = grade;
    SettingData().classNum = classNum;
    state = GradeClassState(grade: grade, classNum: classNum);
  }
}

final gradeClassProvider =
    NotifierProvider<GradeClassNotifier, GradeClassState>(GradeClassNotifier.new);

class NotificationSettings {
  final bool breakfast;
  final String breakfastTime;
  final bool lunch;
  final String lunchTime;
  final bool dinner;
  final String dinnerTime;
  final bool board;

  const NotificationSettings({
    required this.breakfast,
    required this.breakfastTime,
    required this.lunch,
    required this.lunchTime,
    required this.dinner,
    required this.dinnerTime,
    required this.board,
  });

  NotificationSettings copyWith({
    bool? breakfast,
    String? breakfastTime,
    bool? lunch,
    String? lunchTime,
    bool? dinner,
    String? dinnerTime,
    bool? board,
  }) =>
      NotificationSettings(
        breakfast: breakfast ?? this.breakfast,
        breakfastTime: breakfastTime ?? this.breakfastTime,
        lunch: lunch ?? this.lunch,
        lunchTime: lunchTime ?? this.lunchTime,
        dinner: dinner ?? this.dinner,
        dinnerTime: dinnerTime ?? this.dinnerTime,
        board: board ?? this.board,
      );
}

class NotificationSettingsNotifier extends Notifier<NotificationSettings> {
  @override
  NotificationSettings build() {
    final s = SettingData();
    return NotificationSettings(
      breakfast: s.isBreakfastNotificationOn,
      breakfastTime: s.breakfastTime,
      lunch: s.isLunchNotificationOn,
      lunchTime: s.lunchTime,
      dinner: s.isDinnerNotificationOn,
      dinnerTime: s.dinnerTime,
      board: s.isBoardNotificationOn,
    );
  }

  void setBreakfast({bool? on, String? time}) {
    final s = SettingData();
    if (on != null) s.isBreakfastNotificationOn = on;
    if (time != null) s.breakfastTime = time;
    state = state.copyWith(breakfast: on, breakfastTime: time);
  }

  void setLunch({bool? on, String? time}) {
    final s = SettingData();
    if (on != null) s.isLunchNotificationOn = on;
    if (time != null) s.lunchTime = time;
    state = state.copyWith(lunch: on, lunchTime: time);
  }

  void setDinner({bool? on, String? time}) {
    final s = SettingData();
    if (on != null) s.isDinnerNotificationOn = on;
    if (time != null) s.dinnerTime = time;
    state = state.copyWith(dinner: on, dinnerTime: time);
  }

  void setBoard(bool on) {
    SettingData().isBoardNotificationOn = on;
    state = state.copyWith(board: on);
  }
}

final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  NotificationSettingsNotifier.new,
);


class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final code = SettingData().localeCode;
    return code.isEmpty ? null : Locale(code);
  }

  void setLocale(Locale? locale) {
    SettingData().localeCode = locale?.languageCode ?? '';
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);


class AppRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}

final appRefreshProvider =
    NotifierProvider<AppRefreshNotifier, int>(AppRefreshNotifier.new);


/// 접근성 설정 (큰 글씨 / 고대비 / 색맹 보정)
class A11ySettings {
  final double fontScale;
  final bool highContrast;
  final String colorBlindMode;

  const A11ySettings({
    required this.fontScale,
    required this.highContrast,
    required this.colorBlindMode,
  });

  A11ySettings copyWith({double? fontScale, bool? highContrast, String? colorBlindMode}) =>
      A11ySettings(
        fontScale: fontScale ?? this.fontScale,
        highContrast: highContrast ?? this.highContrast,
        colorBlindMode: colorBlindMode ?? this.colorBlindMode,
      );
}

class A11ySettingsNotifier extends Notifier<A11ySettings> {
  @override
  A11ySettings build() {
    final s = SettingData();
    return A11ySettings(
      fontScale: s.fontScale,
      highContrast: s.highContrast,
      colorBlindMode: s.colorBlindMode,
    );
  }

  void setFontScale(double value) {
    SettingData().fontScale = value;
    state = state.copyWith(fontScale: value);
  }

  void setHighContrast(bool value) {
    SettingData().highContrast = value;
    state = state.copyWith(highContrast: value);
  }

  void setColorBlindMode(String value) {
    SettingData().colorBlindMode = value;
    state = state.copyWith(colorBlindMode: value);
  }
}

final a11ySettingsProvider =
    NotifierProvider<A11ySettingsNotifier, A11ySettings>(A11ySettingsNotifier.new);
