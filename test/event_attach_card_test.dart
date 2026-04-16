import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/widgets/event_attach_card.dart';

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

  testWidgets('eventContent와 카드 타이틀/추가 버튼 표시', (tester) async {
    await tester.pumpWidget(wrap(EventAttachCard(
      eventDate: DateTime(2026, 4, 16),
      eventContent: '체육대회',
      startTime: -1,
      endTime: -1,
      onAdd: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('일정 공유'), findsOneWidget);
    expect(find.text('체육대회'), findsOneWidget);
    expect(find.text('내 일정에 추가'), findsOneWidget);
  });

  testWidgets('startTime/endTime이 음수면 시간 표기 없음', (tester) async {
    await tester.pumpWidget(wrap(EventAttachCard(
      eventDate: DateTime(2026, 4, 16),
      eventContent: '행사',
      startTime: -1,
      endTime: -1,
      onAdd: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('오전'), findsNothing);
    expect(find.textContaining('오후'), findsNothing);
  });

  testWidgets('오전 시간 포맷', (tester) async {
    // 9:30 = 570분
    await tester.pumpWidget(wrap(EventAttachCard(
      eventDate: DateTime(2026, 4, 16),
      eventContent: '조회',
      startTime: 570,
      endTime: 600,
      onAdd: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('오전 9:30'), findsOneWidget);
    expect(find.textContaining('오전 10:00'), findsOneWidget);
  });

  testWidgets('오후 시간 포맷', (tester) async {
    // 14:15 = 855분, 15:00 = 900분
    await tester.pumpWidget(wrap(EventAttachCard(
      eventDate: DateTime(2026, 4, 16),
      eventContent: '방과후',
      startTime: 855,
      endTime: 900,
      onAdd: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('오후 2:15'), findsOneWidget);
    expect(find.textContaining('오후 3:00'), findsOneWidget);
  });

  testWidgets('추가 버튼 탭 시 onAdd 콜백', (tester) async {
    var added = false;
    await tester.pumpWidget(wrap(EventAttachCard(
      eventDate: DateTime(2026, 4, 16),
      eventContent: '축제',
      startTime: -1,
      endTime: -1,
      onAdd: () => added = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    expect(added, isTrue);
  });
}
