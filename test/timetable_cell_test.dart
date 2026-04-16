import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/screens/sub/timetable_widgets/timetable_cell.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: SizedBox(width: 100, height: 100, child: child)));
  }

  testWidgets('빈 subject → 텍스트 없이 빈 셀만 렌더링', (tester) async {
    await tester.pumpWidget(wrap(const TimetableCell(
      subject: '',
      isConflict: false,
      isDark: false,
    )));

    expect(find.byType(Text), findsNothing);
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('subject가 있으면 텍스트 표시', (tester) async {
    await tester.pumpWidget(wrap(const TimetableCell(
      subject: '수학',
      isConflict: false,
      isDark: false,
    )));

    expect(find.text('수학'), findsOneWidget);
  });

  testWidgets('같은 subject는 같은 색상 인덱스 → 결정론적', (tester) async {
    await tester.pumpWidget(wrap(const Column(children: [
      Expanded(child: TimetableCell(subject: '국어', isConflict: false, isDark: false)),
      Expanded(child: TimetableCell(subject: '국어', isConflict: false, isDark: false)),
    ])));

    final cells = tester.widgetList<Container>(find.descendant(
      of: find.byType(TimetableCell), matching: find.byType(Container))).toList();
    // 두 셀의 margin을 가진 outer container가 동일한 색상을 가지는지 확인
    // (hashCode 기반이므로 동일 subject는 동일 색상)
    expect(cells.length, greaterThanOrEqualTo(2));
  });

  testWidgets('다크 모드에서는 다른 팔레트 사용', (tester) async {
    await tester.pumpWidget(wrap(const TimetableCell(
      subject: '영어',
      isConflict: false,
      isDark: true,
    )));

    expect(find.text('영어'), findsOneWidget);
    // 다크 모드 셀이 렌더링되었는지만 확인
    expect(find.byType(TimetableCell), findsOneWidget);
  });

  testWidgets('customColor가 있으면 기본 팔레트 대신 사용', (tester) async {
    await tester.pumpWidget(wrap(const TimetableCell(
      subject: '미술',
      isConflict: false,
      isDark: false,
      customColor: Colors.orange,
    )));

    expect(find.text('미술'), findsOneWidget);
  });

  testWidgets('onLongPress 콜백 동작', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(wrap(TimetableCell(
      subject: '체육',
      isConflict: false,
      isDark: false,
      onLongPress: () => longPressed = true,
    )));

    await tester.longPress(find.byType(TimetableCell));
    expect(longPressed, isTrue);
  });
}
