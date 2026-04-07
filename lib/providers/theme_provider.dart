import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

/// 테마 모드 관리 (라이트/다크/시스템)
///
/// SettingData의 themeModeIndex와 동기화. riverpod_generator 기반.
@Riverpod(keepAlive: true)
class Theme extends _$Theme {
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
