import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/dark_app_colors.dart';
import 'package:hansol_high_school/styles/light_app_colors.dart';

/**
 * 앱 테마 컬러 추상 클래스
 * - 라이트/다크 테마에서 사용할 색상 속성을 추상으로 정의
 * - AnimatedAppColors 싱글턴을 통해 다크/라이트 간 색상 보간(lerp) 지원
 * - _light, _dark 인스턴스로 각 테마의 고정 색상 참조 가능
 * - AppColors.theme으로 현재 보간된 색상에 접근
 */
abstract class AppColors {
  Color get transparent => Colors.transparent;
  Color get black;
  Color get white;
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

  static final AppColors _light = LightAppColors();
  static final AppColors _dark = DarkAppColors();

  static AppColors get theme => AnimatedAppColors.instance;
  static AppColors get lightTheme => _light;
  static AppColors get darkTheme => _dark;
}

class AnimatedAppColors extends AppColors {
  static final AnimatedAppColors instance = AnimatedAppColors._();
  AnimatedAppColors._();

  double _t = 0.0;
  bool _isDark = false;

  void setDark(bool dark, {bool animate = true}) {
    _isDark = dark;
    if (!animate) _t = dark ? 1.0 : 0.0;
  }

  void tick(double t) => _t = t;
  double get progress => _t;
  bool get isDark => _isDark;

  Color _lerp(Color light, Color dark) => Color.lerp(light, dark, _t)!;

  @override Color get black => _lerp(AppColors.lightTheme.black, AppColors.darkTheme.black);
  @override Color get white => _lerp(AppColors.lightTheme.white, AppColors.darkTheme.white);
  @override Color get primaryColor => _lerp(AppColors.lightTheme.primaryColor, AppColors.darkTheme.primaryColor);
  @override Color get secondaryColor => _lerp(AppColors.lightTheme.secondaryColor, AppColors.darkTheme.secondaryColor);
  @override Color get tertiaryColor => _lerp(AppColors.lightTheme.tertiaryColor, AppColors.darkTheme.tertiaryColor);
  @override Color get lighterColor => _lerp(AppColors.lightTheme.lighterColor, AppColors.darkTheme.lighterColor);
  @override Color get lightGreyColor => _lerp(AppColors.lightTheme.lightGreyColor, AppColors.darkTheme.lightGreyColor);
  @override Color get darkGreyColor => _lerp(AppColors.lightTheme.darkGreyColor, AppColors.darkTheme.darkGreyColor);
  @override Color get textFiledFillColor => _lerp(AppColors.lightTheme.textFiledFillColor, AppColors.darkTheme.textFiledFillColor);
  @override Color get settingScreenBackgroundColor => _lerp(AppColors.lightTheme.settingScreenBackgroundColor, AppColors.darkTheme.settingScreenBackgroundColor);
  @override Color get mealCardBackgroundColor => _lerp(AppColors.lightTheme.mealCardBackgroundColor, AppColors.darkTheme.mealCardBackgroundColor);
  @override Color get mealTypeTextColor => _lerp(AppColors.lightTheme.mealTypeTextColor, AppColors.darkTheme.mealTypeTextColor);
  @override Color get mealHeaderIconColor => _lerp(AppColors.lightTheme.mealHeaderIconColor, AppColors.darkTheme.mealHeaderIconColor);
}
