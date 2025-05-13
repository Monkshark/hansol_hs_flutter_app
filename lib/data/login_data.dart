import 'package:shared_preferences/shared_preferences.dart';

class LoginData {
  static final LoginData _instance = LoginData._internal();
  late SharedPreferences _sharedPreferences;

  factory LoginData() {
    return _instance;
  }

  LoginData._internal();

  init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  set schoolNum(String value) =>
      _sharedPreferences.setString('schoolNum', value);
  String get schoolNum => _sharedPreferences.getString('schoolNum') ?? '';

  set name(String value) => _sharedPreferences.setString('name', value);
  String get name => _sharedPreferences.getString('name') ?? '';

  set password(String value) => _sharedPreferences.setString('password', value);
  String get password => _sharedPreferences.getString('password') ?? '';

  set isLogin(bool value) => _sharedPreferences.setBool('isLogin', value);
  bool get isLogin => _sharedPreferences.getBool('isLogin') ?? false;

  set grade(String value) => _sharedPreferences.setString('grade', value);
  String get grade => _sharedPreferences.getString('grade') ?? '';

  set classNum(String value) => _sharedPreferences.setString('classNum', value);
  String get classNum => _sharedPreferences.getString('classNum') ?? '';
}
