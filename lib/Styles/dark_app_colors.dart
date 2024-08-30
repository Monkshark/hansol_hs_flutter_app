import 'package:flutter/material.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';

class DarkAppColors extends AppColors {
  static final DarkAppColors _instance = DarkAppColors._internal();

  factory DarkAppColors() => _instance;

  DarkAppColors._internal();

  @override
  Color get transparent => Colors.transparent;

  @override
  Color get primaryColor => const Color(0xFF3F72AF);

  @override
  Color get secondaryColor => const Color(0xFF198A43);

  @override
  Color get lighterColor => const Color.fromRGBO(63, 114, 175, 0.6);

  @override
  Color get lightGreyColor => Colors.grey[200]!;

  @override
  Color get darkGreyColor => Colors.grey[600]!;

  @override
  Color get textFiledFillColor => Colors.grey[300]!;

  @override
  Color get settingScreenBackgroundColor => const Color(0xFFF8F6F6);
}
