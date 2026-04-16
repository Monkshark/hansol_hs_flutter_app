import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/widgets/error_view.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: child),
    );
  }

  testWidgets('기본 에러 메시지 표시', (tester) async {
    await tester.pumpWidget(wrap(const ErrorView()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('문제가 발생했습니다'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('커스텀 메시지 표시', (tester) async {
    await tester.pumpWidget(wrap(const ErrorView(message: '네트워크 오류')));
    await tester.pumpAndSettle();

    expect(find.text('네트워크 오류'), findsOneWidget);
    expect(find.text('문제가 발생했습니다'), findsNothing);
  });

  testWidgets('커스텀 아이콘 표시', (tester) async {
    await tester.pumpWidget(wrap(const ErrorView(icon: Icons.wifi_off)));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
  });

  testWidgets('onRetry 콜백 시 재시도 버튼 표시 + 클릭', (tester) async {
    var retried = false;
    await tester.pumpWidget(wrap(ErrorView(onRetry: () => retried = true)));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    expect(retried, isTrue);
  });

  testWidgets('onRetry null이면 재시도 버튼 없음', (tester) async {
    await tester.pumpWidget(wrap(const ErrorView()));
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('다크 모드에서 렌더링', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: const Scaffold(body: ErrorView(message: '다크 테스트')),
    ));
    await tester.pumpAndSettle();

    expect(find.text('다크 테스트'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
