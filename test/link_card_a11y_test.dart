import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/widgets/home/link_card.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  Semantics? findLinkSemantics(WidgetTester tester, String label) {
    final list = tester.widgetList<Semantics>(find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.button == true && w.properties.label == label,
    ));
    return list.isNotEmpty ? list.first : null;
  }

  testWidgets('LinkCard에 semantic label + button 속성 존재', (tester) async {
    await tester.pumpWidget(wrap(LinkCard(
      icon: Icons.school,
      label: '학교 홈페이지',
      color: Colors.blue,
      url: 'https://example.com',
    )));

    final semantics = findLinkSemantics(tester, '학교 홈페이지');
    expect(semantics, isNotNull);
    expect(semantics!.properties.button, isTrue);
  });

  testWidgets('label이 다르면 semantic label도 다름', (tester) async {
    await tester.pumpWidget(wrap(LinkCard(
      icon: Icons.restaurant,
      label: '급식 메뉴',
      color: Colors.orange,
      url: 'https://example.com/meal',
    )));

    expect(findLinkSemantics(tester, '급식 메뉴'), isNotNull);
    expect(findLinkSemantics(tester, '학교 홈페이지'), isNull);
  });

  testWidgets('아이콘과 텍스트 렌더링', (tester) async {
    await tester.pumpWidget(wrap(LinkCard(
      icon: Icons.school,
      label: '학교 홈페이지',
      color: Colors.blue,
      url: 'https://example.com',
    )));

    expect(find.byIcon(Icons.school), findsOneWidget);
    expect(find.text('학교 홈페이지'), findsOneWidget);
  });

  testWidgets('다크 모드에서 렌더링 + semantic label 유지', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: LinkCard(
          icon: Icons.school,
          label: '학교 홈페이지',
          color: Colors.blue,
          url: 'https://example.com',
        ),
      ),
    ));

    expect(findLinkSemantics(tester, '학교 홈페이지'), isNotNull);
    expect(find.text('학교 홈페이지'), findsOneWidget);
  });
}
