import 'package:shared_preferences/shared_preferences.dart';

class SettingData {
  static final SettingData _instance = SettingData._internal();
  late SharedPreferences _sharedPreferences;

  factory SettingData() {
    return _instance;
  }

  SettingData._internal();

  init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  set grade(int value) => _sharedPreferences.setInt('Grade', value);
  int get grade => _sharedPreferences.getInt('Grade') ?? 1;

  set classNum(int value) => _sharedPreferences.setInt('Class', value);
  int get classNum => _sharedPreferences.getInt('Class') ?? 1;

  set mealType(int value) => _sharedPreferences.setInt('MealType', value);
  int get mealType => _sharedPreferences.getInt('MealType') ?? 1;
}
