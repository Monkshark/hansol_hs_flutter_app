import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/setting_data.dart';

/// 테마 모드 관리 (라이트/다크/시스템)
///
/// SettingData의 themeModeIndex와 동기화. Riverpod 2.x Notifier 패턴.
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _indexToMode(SettingData().themeModeIndex);

  static ThemeMode _indexToMode(int index) {
    switch (index) {
      case 1:
        return ThemeMode.dark;
      case 2:
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  void setMode(int index) {
    SettingData().themeModeIndex = index;
    state = _indexToMode(index);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
