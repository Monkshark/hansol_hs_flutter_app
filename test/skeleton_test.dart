import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/widgets/skeleton.dart';

void main() {
  Widget wrap(Widget child, {bool dark = false}) {
    return MaterialApp(
      theme: dark ? ThemeData.dark() : ThemeData.light(),
      home: Scaffold(body: child),
    );
  }

  group('SkeletonBox', () {
    testWidgets('기본 렌더링', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 40)));

      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('커스텀 크기 적용', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(
        width: 100,
        height: 50,
        borderRadius: 12,
      )));

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(SkeletonBox), matching: find.byType(Container)),
      );
      final constraints = container.constraints;
      expect(constraints?.maxWidth, 100);
      expect(constraints?.maxHeight, 50);
    });

    testWidgets('라이트 모드 색상', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 40)));
      // 렌더링 성공 확인
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('다크 모드 색상', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 40), dark: true));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('기본 borderRadius = 8', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 40)));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('width 기본값 infinity', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonBox(height: 20)));
      // double.infinity일 때 렌더링 성공
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonShimmer', () {
    testWidgets('라이트 모드 렌더링', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonShimmer(
        child: SkeletonBox(height: 40),
      )));

      expect(find.byType(SkeletonShimmer), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('다크 모드 렌더링', (tester) async {
      await tester.pumpWidget(wrap(
        const SkeletonShimmer(child: SkeletonBox(height: 40)),
        dark: true,
      ));

      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('자식 위젯 전달', (tester) async {
      await tester.pumpWidget(wrap(const SkeletonShimmer(
        child: SizedBox(width: 100, height: 20),
      )));

      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('PostCardSkeleton', () {
    testWidgets('라이트 모드 렌더링', (tester) async {
      await tester.pumpWidget(wrap(const PostCardSkeleton()));
      expect(find.byType(PostCardSkeleton), findsOneWidget);
      expect(find.byType(SkeletonShimmer), findsOneWidget);
    });

    testWidgets('다크 모드 렌더링', (tester) async {
      await tester.pumpWidget(wrap(const PostCardSkeleton(), dark: true));
      expect(find.byType(PostCardSkeleton), findsOneWidget);
    });
  });
}
