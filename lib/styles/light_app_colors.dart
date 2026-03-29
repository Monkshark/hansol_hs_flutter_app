import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/**
 * 라이트모드 색상 정의
 * - AppColors 추상 클래스를 구현하여 라이트 테마 전용 색상 제공
 * - 블루 계열 primaryColor(0xFF3F72AF)와 밝은 배경색 사용
 * - 싱글턴 패턴으로 인스턴스 하나만 유지
 */
class LightAppColors extends AppColors {
  static final LightAppColors _instance = LightAppColors._internal();

  factory LightAppColors() => _instance;

  LightAppColors._internal();

  @override
  Color get black => Colors.black;

  @override
  Color get white => Colors.white;

  @override
  Color get transparent => Colors.transparent;

  @override
  Color get primaryColor => const Color(0xFF3F72AF);

  @override
  Color get secondaryColor => const Color(0xFF198A43);

  @override
  Color get tertiaryColor => const Color(0xFF4D99F4);

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

  @override
  Color get mealCardBackgroundColor => const Color(0xffDBE2EF);

  @override
  Color get mealTypeTextColor => const Color(0xff848484);

  @override
  Color get mealHeaderIconColor => const Color(0xffDBE2EF);
}
