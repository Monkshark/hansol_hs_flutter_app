import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/sub/timetable_widgets/conflict_dialog.dart';

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

  testWidgets('타이틀에 요일/교시 표시', (tester) async {
    await tester.pumpWidget(wrap(const ConflictDialog(
      dayName: '월',
      period: '3',
      subjects: ['수학', '물리'],
    )));
    await tester.pumpAndSettle();

    expect(find.text('월요일 3교시'), findsOneWidget);
    expect(find.text('어떤 과목을 듣나요?'), findsOneWidget);
  });

  testWidgets('각 subject마다 버튼 렌더링', (tester) async {
    await tester.pumpWidget(wrap(const ConflictDialog(
      dayName: '화',
      period: '5',
      subjects: ['영어', '국어', '사회'],
    )));
    await tester.pumpAndSettle();

    expect(find.text('영어'), findsOneWidget);
    expect(find.text('국어'), findsOneWidget);
    expect(find.text('사회'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNWidgets(3));
  });

  testWidgets('subject 버튼 탭 시 해당 subject로 pop', (tester) async {
    String? result;
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return ElevatedButton(
        onPressed: () async {
          result = await showDialog<String>(
            context: context,
            builder: (_) => const ConflictDialog(
              dayName: '수',
              period: '2',
              subjects: ['체육', '음악'],
            ),
          );
        },
        child: const Text('open'),
      );
    })));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('음악'));
    await tester.pumpAndSettle();

    expect(result, '음악');
  });

  testWidgets('subjects 비어있어도 렌더링', (tester) async {
    await tester.pumpWidget(wrap(const ConflictDialog(
      dayName: '목',
      period: '1',
      subjects: [],
    )));
    await tester.pumpAndSettle();

    expect(find.text('목요일 1교시'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
