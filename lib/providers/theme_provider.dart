import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/setting_data.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(_indexToMode(SettingData().themeModeIndex));

  static ThemeMode _indexToMode(int index) {
    switch (index) {
      case 1: return ThemeMode.dark;
      case 2: return ThemeMode.system;
      default: return ThemeMode.light;
    }
  }

  void setMode(int index) {
    SettingData().themeModeIndex = index;
    state = _indexToMode(index);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
