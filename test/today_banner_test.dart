import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/widgets/calendar/today_banner.dart';

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

  testWidgets('count 표시', (tester) async {
    await tester.pumpWidget(wrap(TodayBanner(
      selectedDate: DateTime(2026, 4, 16),
      count: 3,
    )));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('날짜 포맷이 한국 로케일로 표시', (tester) async {
    await tester.pumpWidget(wrap(TodayBanner(
      selectedDate: DateTime(2026, 4, 16),
      count: 1,
    )));
    await tester.pumpAndSettle();

    // common_dateMdE = "M월 d일 (E)"
    expect(find.textContaining('4월 16일'), findsOneWidget);
  });

  testWidgets('count가 0일 때도 렌더링', (tester) async {
    await tester.pumpWidget(wrap(TodayBanner(
      selectedDate: DateTime(2026, 1, 1),
      count: 0,
    )));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('1월 1일'), findsOneWidget);
  });

  testWidgets('큰 count 값 표시', (tester) async {
    await tester.pumpWidget(wrap(TodayBanner(
      selectedDate: DateTime(2026, 12, 31),
      count: 99,
    )));
    await tester.pumpAndSettle();

    expect(find.text('99'), findsOneWidget);
  });
}
