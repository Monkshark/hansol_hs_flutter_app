import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/screens/board/widgets/vote_button.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

void main() {
  setUpAll(() {
    AnimatedAppColors.instance.setDark(false, animate: false);
    AnimatedAppColors.instance.tick(0);
  });

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('비활성 상태에서는 일반 icon과 count 표시', (tester) async {
    await tester.pumpWidget(wrap(VoteButton(
      icon: Icons.thumb_up_outlined,
      activeIcon: Icons.thumb_up,
      count: 5,
      isActive: false,
      activeColor: Colors.blue,
      onTap: () {},
    )));

    expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up), findsNothing);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('활성 상태에서는 activeIcon 표시', (tester) async {
    await tester.pumpWidget(wrap(VoteButton(
      icon: Icons.thumb_up_outlined,
      activeIcon: Icons.thumb_up,
      count: 10,
      isActive: true,
      activeColor: Colors.blue,
      onTap: () {},
    )));

    expect(find.byIcon(Icons.thumb_up), findsOneWidget);
    expect(find.byIcon(Icons.thumb_up_outlined), findsNothing);
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('count가 0일 때도 표시', (tester) async {
    await tester.pumpWidget(wrap(VoteButton(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      count: 0,
      isActive: false,
      activeColor: Colors.red,
      onTap: () {},
    )));

    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('탭 시 onTap 콜백 호출', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(VoteButton(
      icon: Icons.thumb_up_outlined,
      activeIcon: Icons.thumb_up,
      count: 3,
      isActive: false,
      activeColor: Colors.blue,
      onTap: () => tapped = true,
    )));

    await tester.tap(find.byType(VoteButton));
    expect(tapped, isTrue);
  });

  testWidgets('활성 상태에서는 activeColor를 icon과 텍스트에 사용', (tester) async {
    await tester.pumpWidget(wrap(VoteButton(
      icon: Icons.thumb_up_outlined,
      activeIcon: Icons.thumb_up,
      count: 7,
      isActive: true,
      activeColor: Colors.red,
      onTap: () {},
    )));

    final iconWidget = tester.widget<Icon>(find.byIcon(Icons.thumb_up));
    expect(iconWidget.color, Colors.red);

    final textWidget = tester.widget<Text>(find.text('7'));
    expect(textWidget.style?.color, Colors.red);
  });
}
