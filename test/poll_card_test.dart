import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/widgets/poll_card.dart';

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

  testWidgets('투표 카드 타이틀 + 옵션 + 참여자 수 표시', (tester) async {
    await tester.pumpWidget(wrap(PollCard(
      options: const ['짜장', '짬뽕'],
      voters: const {'u1': 0, 'u2': 0, 'u3': 1},
      myVote: null,
      onVote: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('투표'), findsOneWidget);
    expect(find.text('짜장'), findsOneWidget);
    expect(find.text('짬뽕'), findsOneWidget);
    expect(find.text('3명 참여'), findsOneWidget);
  });

  testWidgets('투표 전에는 퍼센트 미표시', (tester) async {
    await tester.pumpWidget(wrap(PollCard(
      options: const ['A', 'B'],
      voters: const {'u1': 0},
      myVote: null,
      onVote: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('내가 투표하면 퍼센트 표시 + myVote에 체크 아이콘', (tester) async {
    await tester.pumpWidget(wrap(PollCard(
      options: const ['A', 'B'],
      voters: const {'me': 0, 'u2': 1},
      myVote: 0,
      onVote: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('50%'), findsNWidgets(2));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('투표 전 옵션 탭 시 onVote 콜백', (tester) async {
    int? voted;
    await tester.pumpWidget(wrap(PollCard(
      options: const ['A', 'B'],
      voters: const {},
      myVote: null,
      onVote: (i) => voted = i,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    expect(voted, 1);
  });

  testWidgets('이미 투표한 뒤에는 onVote 호출 안됨', (tester) async {
    var called = false;
    await tester.pumpWidget(wrap(PollCard(
      options: const ['A', 'B'],
      voters: const {'me': 0},
      myVote: 0,
      onVote: (_) => called = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    expect(called, isFalse);
  });

  testWidgets('참여자 0명일 때도 렌더링', (tester) async {
    await tester.pumpWidget(wrap(PollCard(
      options: const ['A'],
      voters: const {},
      myVote: null,
      onVote: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('0명 참여'), findsOneWidget);
  });
}
