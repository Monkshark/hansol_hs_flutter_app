import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_toggle_row.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

void main() {
  setUpAll(() {
    AnimatedAppColors.instance.setDark(false, animate: false);
    AnimatedAppColors.instance.tick(0);
  });

  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  testWidgets('비활성 상태 렌더링', (tester) async {
    await tester.pumpWidget(wrap(WriteToggleRow(
      value: false,
      onTap: () {},
      label: '공지로 등록',
      activeColor: Colors.blue,
    )));

    expect(find.text('공지로 등록'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('활성 상태 → 체크 아이콘 표시', (tester) async {
    await tester.pumpWidget(wrap(WriteToggleRow(
      value: true,
      onTap: () {},
      label: '익명',
      activeColor: Colors.red,
    )));

    expect(find.text('익명'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('탭 시 onTap 콜백 호출', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(WriteToggleRow(
      value: false,
      onTap: () => tapped = true,
      label: '테스트',
      activeColor: Colors.blue,
    )));

    await tester.tap(find.text('테스트'));
    expect(tapped, isTrue);
  });

  testWidgets('아이콘 파라미터 전달 시 아이콘 표시', (tester) async {
    await tester.pumpWidget(wrap(WriteToggleRow(
      value: false,
      onTap: () {},
      label: '공지',
      activeColor: Colors.blue,
      icon: Icons.push_pin,
      iconColor: Colors.orange,
    )));

    expect(find.byIcon(Icons.push_pin), findsOneWidget);
  });

  testWidgets('아이콘 없으면 아이콘 위젯 없음', (tester) async {
    await tester.pumpWidget(wrap(WriteToggleRow(
      value: false,
      onTap: () {},
      label: '라벨',
      activeColor: Colors.blue,
    )));

    expect(find.byIcon(Icons.push_pin), findsNothing);
  });

  testWidgets('labelWeight 적용', (tester) async {
    await tester.pumpWidget(wrap(WriteToggleRow(
      value: false,
      onTap: () {},
      label: '볼드',
      activeColor: Colors.blue,
      labelWeight: FontWeight.bold,
    )));

    final text = tester.widget<Text>(find.text('볼드'));
    expect(text.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('value 토글 시 UI 변경', (tester) async {
    var value = false;
    late StateSetter setter;
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) {
        setter = setState;
        return WriteToggleRow(
          value: value,
          onTap: () => setter(() => value = !value),
          label: '토글',
          activeColor: Colors.green,
        );
      },
    )));

    expect(find.byIcon(Icons.check), findsNothing);

    await tester.tap(find.text('토글'));
    await tester.pump();

    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
