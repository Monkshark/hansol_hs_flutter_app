import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 다크모드 색상 정의
/// - 토스 스타일 네이비 계열 배경색 사용 (0xFF191B20 등)
/// - AppColors 추상 클래스를 구현하여 다크 테마 전용 색상 제공
/// - 싱글턴 패턴으로 인스턴스 하나만 유지
class DarkAppColors extends AppColors {
  static final DarkAppColors _instance = DarkAppColors._internal();
  factory DarkAppColors() => _instance;
  DarkAppColors._internal();

  @override Color get black => const Color(0xFFEEEEEE);
  @override Color get white => const Color(0xFF191B20);
  @override Color get transparent => Colors.transparent;
  @override Color get primaryColor => const Color(0xFF3D5A80);
  @override Color get secondaryColor => const Color(0xFF4CAF50);
  @override Color get tertiaryColor => const Color(0xFF7EB8DA);
  @override Color get lighterColor => const Color.fromRGBO(61, 90, 128, 0.5);
  @override Color get lightGreyColor => const Color(0xFF252830);
  @override Color get darkGreyColor => const Color(0xFF8B8F99);
  @override Color get textFiledFillColor => const Color(0xFF2A2D35);
  @override Color get settingScreenBackgroundColor => const Color(0xFF17191E);
  @override Color get mealCardBackgroundColor => const Color(0xFF1E2028);
  @override Color get mealTypeTextColor => const Color(0xFF8B8F99);
  @override Color get mealHeaderIconColor => const Color(0xFF2A2D35);
}
