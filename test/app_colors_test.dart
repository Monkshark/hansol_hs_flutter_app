import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

void main() {
  group('AnimatedAppColors', () {
    test('싱글톤 인스턴스', () {
      final a = AnimatedAppColors.instance;
      final b = AnimatedAppColors.instance;
      expect(identical(a, b), isTrue);
    });

    test('setDark(false) → 라이트 모드 색상', () {
      AnimatedAppColors.instance.setDark(false, animate: false);
      AnimatedAppColors.instance.tick(0);

      expect(AnimatedAppColors.instance.primaryColor, isNotNull);
      expect(AnimatedAppColors.instance.black, isNotNull);
      expect(AnimatedAppColors.instance.white, isNotNull);
    });

    test('setDark(true) → 다크 모드 색상', () {
      AnimatedAppColors.instance.setDark(true, animate: false);
      AnimatedAppColors.instance.tick(0);

      expect(AnimatedAppColors.instance.primaryColor, isNotNull);
    });

    test('라이트/다크 색상 차이', () {
      final lightBg = AppColors.lightTheme.settingScreenBackgroundColor;
      final darkBg = AppColors.darkTheme.settingScreenBackgroundColor;

      expect(lightBg, isNot(equals(darkBg)));
    });
  });

  group('AppColors static 접근', () {
    test('theme은 AnimatedAppColors 인스턴스', () {
      expect(AppColors.theme, isA<AnimatedAppColors>());
    });

    test('lightTheme 접근 가능', () {
      expect(AppColors.lightTheme, isNotNull);
      expect(AppColors.lightTheme.primaryColor, isNotNull);
    });

    test('darkTheme 접근 가능', () {
      expect(AppColors.darkTheme, isNotNull);
      expect(AppColors.darkTheme.primaryColor, isNotNull);
    });

    test('transparent 색상', () {
      expect(AppColors.theme.transparent, Colors.transparent);
    });
  });

  group('색상 속성', () {
    setUp(() {
      AnimatedAppColors.instance.setDark(false, animate: false);
      AnimatedAppColors.instance.tick(0);
    });

    test('primaryColor가 불투명', () {
      expect(AppColors.theme.primaryColor.a, 1.0);
    });

    test('secondaryColor 존재', () {
      expect(AppColors.theme.secondaryColor, isNotNull);
    });

    test('tertiaryColor 존재', () {
      expect(AppColors.theme.tertiaryColor, isNotNull);
    });

    test('lightGreyColor 존재', () {
      expect(AppColors.theme.lightGreyColor, isNotNull);
    });

    test('darkGreyColor 존재', () {
      expect(AppColors.theme.darkGreyColor, isNotNull);
    });

    test('mealCardBackgroundColor 존재', () {
      expect(AppColors.theme.mealCardBackgroundColor, isNotNull);
    });

    test('mealTypeTextColor 존재', () {
      expect(AppColors.theme.mealTypeTextColor, isNotNull);
    });

    test('mealHeaderIconColor 존재', () {
      expect(AppColors.theme.mealHeaderIconColor, isNotNull);
    });

    test('textFiledFillColor 존재', () {
      expect(AppColors.theme.textFiledFillColor, isNotNull);
    });
  });
}
