import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/write_widgets/write_category_selector.dart';
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

  const categories = ['자유', '질문', '정보공유', '분실물'];

  testWidgets('카테고리 목록 렌더링', (tester) async {
    await tester.pumpWidget(wrap(WriteCategorySelector(
      categoryKeys: categories,
      selectedCategory: '자유',
      onCategoryChanged: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('카테고리'), findsOneWidget);
    expect(find.text('자유'), findsOneWidget);
    expect(find.text('질문'), findsOneWidget);
    expect(find.text('정보공유'), findsOneWidget);
    expect(find.text('분실물'), findsOneWidget);
  });

  testWidgets('카테고리 선택 콜백', (tester) async {
    String? selected;
    await tester.pumpWidget(wrap(WriteCategorySelector(
      categoryKeys: categories,
      selectedCategory: '자유',
      onCategoryChanged: (cat) => selected = cat,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('질문'));
    expect(selected, '질문');
  });

  testWidgets('선택된 카테고리 스타일 구분', (tester) async {
    await tester.pumpWidget(wrap(WriteCategorySelector(
      categoryKeys: categories,
      selectedCategory: '질문',
      onCategoryChanged: (_) {},
    )));
    await tester.pumpAndSettle();

    // 선택된 카테고리 텍스트 색상은 흰색
    final selectedText = tester.widget<Text>(find.text('질문'));
    expect(selectedText.style?.color, Colors.white);

    // 비선택 카테고리는 darkGrey
    final unselectedText = tester.widget<Text>(find.text('자유'));
    expect(selectedText.style?.color, isNot(equals(unselectedText.style?.color)));
  });

  testWidgets('빈 카테고리 리스트', (tester) async {
    await tester.pumpWidget(wrap(WriteCategorySelector(
      categoryKeys: const [],
      selectedCategory: '',
      onCategoryChanged: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.text('카테고리'), findsOneWidget);
    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('카테고리 변경 시 UI 업데이트', (tester) async {
    var current = '자유';
    late StateSetter setter;
    await tester.pumpWidget(wrap(StatefulBuilder(
      builder: (context, setState) {
        setter = setState;
        return WriteCategorySelector(
          categoryKeys: categories,
          selectedCategory: current,
          onCategoryChanged: (cat) => setter(() => current = cat),
        );
      },
    )));
    await tester.pumpAndSettle();

    // 처음 '자유' 선택 → 흰색
    var freeText = tester.widget<Text>(find.text('자유'));
    expect(freeText.style?.color, Colors.white);

    // '정보공유' 탭
    await tester.tap(find.text('정보공유'));
    await tester.pumpAndSettle();

    // 이제 '정보공유'가 선택 → 흰색
    final infoText = tester.widget<Text>(find.text('정보공유'));
    expect(infoText.style?.color, Colors.white);

    // '자유'는 비선택
    freeText = tester.widget<Text>(find.text('자유'));
    expect(freeText.style?.color, isNot(Colors.white));
  });

  testWidgets('수평 스크롤 가능', (tester) async {
    await tester.pumpWidget(wrap(WriteCategorySelector(
      categoryKeys: categories,
      selectedCategory: '자유',
      onCategoryChanged: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    final listView = tester.widget<ListView>(find.byType(ListView));
    expect(listView.scrollDirection, Axis.horizontal);
  });
}
