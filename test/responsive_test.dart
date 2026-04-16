import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/styles/responsive.dart';

void main() {
  Widget wrapWithSize(Size size, Widget Function(BuildContext) builder) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        home: Builder(builder: (context) => Scaffold(body: builder(context))),
      ),
    );
  }

  group('w() — 너비 기준 스케일링', () {
    testWidgets('기준 폭(412)에서 1:1 비율', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(412, 915), (context) {
        result = Responsive.w(context, 100);
        return const SizedBox();
      }));
      expect(result, closeTo(100, 1));
    });

    testWidgets('작은 화면에서 축소 (360px)', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(360, 800), (context) {
        result = Responsive.w(context, 100);
        return const SizedBox();
      }));
      expect(result, closeTo(87.4, 1));
    });

    testWidgets('큰 화면에서 확대 (500px)', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(500, 900), (context) {
        result = Responsive.w(context, 100);
        return const SizedBox();
      }));
      expect(result, greaterThan(100));
    });

    testWidgets('0 입력 → 0 반환', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(412, 915), (context) {
        result = Responsive.w(context, 0);
        return const SizedBox();
      }));
      expect(result, 0);
    });
  });

  group('h() — 높이 기준 스케일링', () {
    testWidgets('기준 높이(915)에서 1:1 비율', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(412, 915), (context) {
        result = Responsive.h(context, 100);
        return const SizedBox();
      }));
      expect(result, closeTo(100, 1));
    });

    testWidgets('작은 높이에서 축소 (700px)', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(412, 700), (context) {
        result = Responsive.h(context, 100);
        return const SizedBox();
      }));
      expect(result, closeTo(76.5, 1));
    });
  });

  group('sp() — 폰트 스케일링', () {
    testWidgets('기준 크기에서 원본과 유사', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(412, 915), (context) {
        result = Responsive.sp(context, 14);
        return const SizedBox();
      }));
      expect(result, closeTo(14, 1));
    });

    testWidgets('최소값 클램프 (size * 0.8)', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(200, 400), (context) {
        result = Responsive.sp(context, 14);
        return const SizedBox();
      }));
      expect(result, greaterThanOrEqualTo(14 * 0.8));
    });

    testWidgets('최대값 클램프 (size * 1.3)', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(800, 1600), (context) {
        result = Responsive.sp(context, 14);
        return const SizedBox();
      }));
      expect(result, lessThanOrEqualTo(14 * 1.3));
    });
  });

  group('r() — min(w, h) 기준 스케일링', () {
    testWidgets('기준 크기에서 원본과 유사', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(412, 915), (context) {
        result = Responsive.r(context, 48);
        return const SizedBox();
      }));
      expect(result, closeTo(48, 1));
    });

    testWidgets('폭이 좁으면 폭 기준', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(300, 915), (context) {
        result = Responsive.r(context, 48);
        return const SizedBox();
      }));
      // 300/412 = 0.728, 915/915 = 1.0, min = 0.728
      expect(result, closeTo(48 * 300 / 412, 1));
    });
  });

  group('태블릿 가로모드', () {
    testWidgets('w()에서 contentWidth 사용 (width > height)', (tester) async {
      late double result;
      // 태블릿 가로: 1024x768. contentWidth = 768 * 9/16 = 432
      await tester.pumpWidget(wrapWithSize(const Size(1024, 768), (context) {
        result = Responsive.w(context, 100);
        return const SizedBox();
      }));
      // 432 / 412 * 100 ≈ 104.9
      expect(result, closeTo(104.9, 1));
    });

    testWidgets('sp()에서 contentWidth 사용', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(1024, 768), (context) {
        result = Responsive.sp(context, 14);
        return const SizedBox();
      }));
      // contentWidth = 432, scale = 432/412 ≈ 1.049
      expect(result, closeTo(14 * 432 / 412, 0.5));
    });

    testWidgets('세로 모드에서는 screen.width 사용', (tester) async {
      late double result;
      await tester.pumpWidget(wrapWithSize(const Size(768, 1024), (context) {
        result = Responsive.w(context, 100);
        return const SizedBox();
      }));
      // 세로: contentWidth = 768, 768/412 * 100 ≈ 186.4
      expect(result, closeTo(186.4, 1));
    });
  });
}
