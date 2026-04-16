import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/exceptions.dart';
import 'package:hansol_high_school/widgets/error_snackbar.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('NetworkException → 네트워크 메시지', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, const NetworkException('test')),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('네트워크 연결을 확인해주세요'), findsOneWidget);
  });

  testWidgets('ApiException → API 메시지', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, const ApiException('test')),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('데이터를 불러올 수 없습니다'), findsOneWidget);
  });

  testWidgets('AuthException → 로그인 메시지', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, const AuthException('test')),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('로그인이 필요합니다'), findsOneWidget);
  });

  testWidgets('AppException → 커스텀 메시지', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, const AppException('커스텀 에러 메시지')),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('커스텀 에러 메시지'), findsOneWidget);
  });

  testWidgets('일반 Exception → 기본 메시지', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, Exception('unknown')),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('오류가 발생했습니다'), findsOneWidget);
  });

  testWidgets('String 에러 → 기본 메시지', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, 'string error'),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.text('오류가 발생했습니다'), findsOneWidget);
  });

  testWidgets('SnackBar가 실제로 표시됨', (tester) async {
    await tester.pumpWidget(wrap(Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showErrorSnackbar(context, const NetworkException('test')),
        child: const Text('trigger'),
      ),
    )));

    await tester.tap(find.text('trigger'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
  });
}
