import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:hansol_high_school/Styles/dark_app_colors.dart';
import 'package:hansol_high_school/Styles/light_app_colors.dart';

abstract class AppColors {
  Color get transparent => Colors.transparent;

  Color get black => Colors.black;
  Color get white => Colors.white;

  Color get primaryColor => const Color(0xff3F72AF);
  Color get secondaryColor => const Color(0xff198A43);
  Color get tertiaryColor => const Color(0xFF4D99F4);
  Color get lighterColor => const Color.fromRGBO(63, 114, 175, 0.6);
  Color get lightGreyColor => Colors.grey[200]!;
  Color get darkGreyColor => Colors.grey[600]!;
  Color get textFiledFillColor => Colors.grey[300]!;
  Color get settingScreenBackgroundColor => const Color(0xffF8F6F6);
  Color get mealCardBackgroundColor => const Color(0xffDBE2EF);
  Color get mealTypeTextColor => const Color(0xff848484);
  Color get mealHeaderIconColor => const Color(0xffDBE2EF);

  static AppColors get theme {
    return SettingData().isDarkMode ? DarkAppColors() : LightAppColors();
  }
}
