import 'package:shared_preferences/shared_preferences.dart';

class SettingData {
  static final SettingData _instance = SettingData._internal();
  late SharedPreferences _sharedPreferences;

  factory SettingData() {
    return _instance;
  }

  SettingData._internal();

  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  set grade(int value) => _sharedPreferences.setInt('Grade', value);
  int get grade => _sharedPreferences.getInt('Grade') ?? 0;

  set classNum(int value) => _sharedPreferences.setInt('Class', value);
  int get classNum => _sharedPreferences.getInt('Class') ?? 0;

  bool get isGradeSet => grade > 0 && classNum > 0;

  set isDarkMode(bool value) => _sharedPreferences.setBool('isDarkMode', value);
  bool get isDarkMode => _sharedPreferences.getBool('isDarkMode') ?? false;

  set themeModeIndex(int value) => _sharedPreferences.setInt('themeModeIndex', value);
  int get themeModeIndex => _sharedPreferences.getInt('themeModeIndex') ?? 2;

  set isBreakfastNotificationOn(bool value) =>
      _sharedPreferences.setBool('isBreakfastNotificationOn', value);
  bool get isBreakfastNotificationOn =>
      _sharedPreferences.getBool('isBreakfastNotificationOn') ?? true;

  set breakfastTime(String value) =>
      _sharedPreferences.setString('breakfastTime', value);
  String get breakfastTime =>
      _sharedPreferences.getString('breakfastTime') ?? '06:30';

  set isLunchNotificationOn(bool value) =>
      _sharedPreferences.setBool('isLunchNotificationOn', value);
  bool get isLunchNotificationOn =>
      _sharedPreferences.getBool('isLunchNotificationOn') ?? true;

  set lunchTime(String value) =>
      _sharedPreferences.setString('lunchTime', value);
  String get lunchTime => _sharedPreferences.getString('lunchTime') ?? '12:00';

  set isDinnerNotificationOn(bool value) =>
      _sharedPreferences.setBool('isDinnerNotificationOn', value);
  bool get isDinnerNotificationOn =>
      _sharedPreferences.getBool('isDinnerNotificationOn') ?? true;

  set dinnerTime(String value) =>
      _sharedPreferences.setString('dinnerTime', value);
  String get dinnerTime =>
      _sharedPreferences.getString('dinnerTime') ?? '17:00';

  set isBoardNotificationOn(bool value) =>
      _sharedPreferences.setBool('isBoardNotificationOn', value);
  bool get isBoardNotificationOn =>
      _sharedPreferences.getBool('isBoardNotificationOn') ?? true;

  set localeCode(String value) => _sharedPreferences.setString('localeCode', value);
  String get localeCode => _sharedPreferences.getString('localeCode') ?? '';

  bool getBool(String key, {bool defaultValue = false}) =>
      _sharedPreferences.getBool(key) ?? defaultValue;
  void setBool(String key, bool value) =>
      _sharedPreferences.setBool(key, value);
}
