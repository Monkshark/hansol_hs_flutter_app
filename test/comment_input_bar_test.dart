import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/widgets/comment_input_bar.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

void main() {
  setUpAll(() {
    AnimatedAppColors.instance.setDark(false, animate: false);
    AnimatedAppColors.instance.tick(0);
  });

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

  testWidgets('기본 상태 렌더링', (tester) async {
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: null,
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('익명'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.reply), findsNothing);
  });

  testWidgets('댓글 입력 가능', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: controller,
      sending: false,
      commentAnonymous: false,
      replyToName: null,
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '테스트 댓글');
    expect(controller.text, '테스트 댓글');
  });

  testWidgets('전송 버튼 클릭 시 onSubmit 호출', (tester) async {
    var submitted = false;
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: null,
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () => submitted = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send));
    expect(submitted, isTrue);
  });

  testWidgets('sending=true이면 전송 버튼 비활성', (tester) async {
    var submitted = false;
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: true,
      commentAnonymous: false,
      replyToName: null,
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () => submitted = true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.send));
    expect(submitted, isFalse);
  });

  testWidgets('익명 토글 클릭 시 onToggleAnonymous 호출', (tester) async {
    var toggled = false;
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: null,
      onToggleAnonymous: () => toggled = true,
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('익명'));
    expect(toggled, isTrue);
  });

  testWidgets('replyToName 있으면 답글 표시자 표시', (tester) async {
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: '홍길동',
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.reply), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('replyToName null이면 답글 표시자 없음', (tester) async {
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: null,
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.reply), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('답글 취소 버튼 클릭 시 onCancelReply 호출', (tester) async {
    var cancelled = false;
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: '김철수',
      onToggleAnonymous: () {},
      onCancelReply: () => cancelled = true,
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    expect(cancelled, isTrue);
  });

  testWidgets('replyToName 시 힌트 텍스트 변경', (tester) async {
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: false,
      replyToName: '이영희',
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    // 힌트 텍스트가 @이영희로 변경
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.hintText, '@이영희');
  });

  testWidgets('commentAnonymous=true 시 스타일 변경', (tester) async {
    await tester.pumpWidget(wrap(CommentInputBar(
      controller: TextEditingController(),
      sending: false,
      commentAnonymous: true,
      replyToName: null,
      onToggleAnonymous: () {},
      onCancelReply: () {},
      onSubmit: () {},
    )));
    await tester.pumpAndSettle();

    // 익명 텍스트 위젯은 primary color로 표시되어야 함
    final anonText = tester.widget<Text>(find.text('익명'));
    expect(anonText.style?.color, AppColors.theme.primaryColor);
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
      home: Scaffold(
        body: CommentInputBar(
          controller: TextEditingController(),
          sending: false,
          commentAnonymous: false,
          replyToName: null,
          onToggleAnonymous: () {},
          onCancelReply: () {},
          onSubmit: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('익명'), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });
}
