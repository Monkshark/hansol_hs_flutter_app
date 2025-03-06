import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/setting_data.dart';
import 'package:hansol_high_school/Styles/dark_app_colors.dart';
import 'package:hansol_high_school/Styles/light_app_colors.dart';

abstract class AppColors {
  Color get transparent => Colors.transparent;

  Color get black => Colors.black;
  Color get white => Colors.white;

  Color get primaryColor;
  Color get secondaryColor;
  Color get tertiaryColor;
  Color get lighterColor;
  Color get lightGreyColor;
  Color get darkGreyColor;
  Color get textFiledFillColor;
  Color get settingScreenBackgroundColor;
  Color get mealCardBackgroundColor;
  Color get mealTypeTextColor;
  Color get mealHeaderIconColor;

  static AppColors get theme {
    return SettingData().isDarkMode ? DarkAppColors() : LightAppColors();
  }
}
