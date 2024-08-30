import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:hansol_high_school/Styles/dark_app_colors.dart';
import 'package:hansol_high_school/Styles/light_app_colors.dart';

abstract class AppColors {
  Color get transparent => Colors.transparent;

  Color get primaryColor => const Color(0xFF3F72AF);
  Color get secondaryColor => const Color(0xFF198A43);
  Color get lighterColor => const Color.fromRGBO(63, 114, 175, 0.6);
  Color get lightGreyColor => Colors.grey[200]!;
  Color get darkGreyColor => Colors.grey[600]!;
  Color get textFiledFillColor => Colors.grey[300]!;
  Color get settingScreenBackgroundColor => const Color(0xFFF8F6F6);

  static AppColors get color {
    return SettingData().isDarkMode ? DarkAppColors() : LightAppColors();
  }
}
