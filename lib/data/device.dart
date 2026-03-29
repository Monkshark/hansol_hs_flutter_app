import 'package:flutter/material.dart';

/// 디바이스 크기 계산 유틸리티
///
/// - 화면 너비/높이 측정 및 태블릿 여부 감지
/// - BuildContext 기반 초기화
class Device {
  static late double width;
  static late double height;

  static late bool isTablet;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
    isTablet = width > 500;
  }

  static double getWidth(double percent) {
    return width / 100 * percent;
  }

  static double getHeight(double percent) {
    return height / 100 * percent;
  }
}

