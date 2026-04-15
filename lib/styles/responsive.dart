import 'dart:math';
import 'package:flutter/widgets.dart';

/// S23 Ultra 기준 반응형 스케일링 유틸리티.
///
/// 기준 해상도(412 x 915)를 기본으로, 현재 기기 크기에 맞게
/// 비율을 유지하면서 스케일링한다.
/// 태블릿 가로모드에서는 ConstrainedBox(height*9/16)로 제한된
/// 콘텐츠 영역 기준으로 계산한다.
class Responsive {
  Responsive._();

  static const double _baseWidth = 412.0;
  static const double _baseHeight = 915.0;

  /// 태블릿 가로모드에서 실제 콘텐츠 폭을 반환.
  /// main.dart의 ConstrainedBox(maxWidth: height * 9/16)와 동일한 로직.
  static double _contentWidth(Size screen) {
    if (screen.width > screen.height) {
      return screen.height * (9 / 16);
    }
    return screen.width;
  }

  /// 너비 기준 스케일링 (아이콘, 가로 패딩, 가로 크기 등)
  static double w(BuildContext context, double size) {
    final screen = MediaQuery.of(context).size;
    return size * _contentWidth(screen) / _baseWidth;
  }

  /// 높이 기준 스케일링 (세로 간격, 세로 크기 등)
  static double h(BuildContext context, double size) {
    return size * MediaQuery.of(context).size.height / _baseHeight;
  }

  /// 폰트 크기 스케일링 (콘텐츠 폭 기준, min/max 클램프)
  static double sp(BuildContext context, double size) {
    final screen = MediaQuery.of(context).size;
    final scale = _contentWidth(screen) / _baseWidth;
    return (size * scale).clamp(size * 0.8, size * 1.3);
  }

  /// 너비/높이 중 작은 쪽 기준 스케일링 (정사각 아이콘, 아바타 등)
  static double r(BuildContext context, double size) {
    final screen = MediaQuery.of(context).size;
    final cw = _contentWidth(screen);
    final scale = min(cw / _baseWidth, screen.height / _baseHeight);
    return size * scale;
  }
}
