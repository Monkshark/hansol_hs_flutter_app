import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

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
