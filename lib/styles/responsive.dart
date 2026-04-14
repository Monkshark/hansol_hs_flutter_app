import 'dart:math';
import 'package:flutter/widgets.dart';

/// S23 Ultra 기준 반응형 스케일링 유틸리티.
///
/// 기준 해상도(412 x 915)를 기본으로, 현재 기기 크기에 맞게
/// 비율을 유지하면서 스케일링한다.
class Responsive {
  Responsive._();

  static const double _baseWidth = 412.0;
  static const double _baseHeight = 915.0;

  /// 너비 기준 스케일링 (아이콘, 가로 패딩, 가로 크기 등)
  static double w(BuildContext context, double size) {
    return size * MediaQuery.of(context).size.width / _baseWidth;
  }

  /// 높이 기준 스케일링 (세로 간격, 세로 크기 등)
  static double h(BuildContext context, double size) {
    return size * MediaQuery.of(context).size.height / _baseHeight;
  }

  /// 폰트 크기 스케일링 (너비 기준, min/max 클램프)
  static double sp(BuildContext context, double size) {
    final scale = MediaQuery.of(context).size.width / _baseWidth;
    return (size * scale).clamp(size * 0.8, size * 1.3);
  }

  /// 너비/높이 중 작은 쪽 기준 스케일링 (정사각 아이콘, 아바타 등)
  static double r(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scale = min(screenWidth / _baseWidth, screenHeight / _baseHeight);
    return size * scale;
  }
}
