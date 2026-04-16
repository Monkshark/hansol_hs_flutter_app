import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

void main() {
  setUpAll(() {
    AnimatedAppColors.instance.setDark(false, animate: false);
    AnimatedAppColors.instance.tick(0);
  });

  group('상수', () {
    test('boardKeys에 8개 카테고리 포함', () {
      expect(BoardCategories.boardKeys.length, 8);
      expect(BoardCategories.boardKeys, contains('전체'));
      expect(BoardCategories.boardKeys, contains('인기글'));
      expect(BoardCategories.boardKeys, contains('자유'));
    });

    test('writeKeys에 전체/인기글 미포함', () {
      expect(BoardCategories.writeKeys, isNot(contains('전체')));
      expect(BoardCategories.writeKeys, isNot(contains('인기글')));
      expect(BoardCategories.writeKeys.length, 6);
    });

    test('topicKey 매핑', () {
      expect(BoardCategories.topicKey['자유'], 'free');
      expect(BoardCategories.topicKey['질문'], 'question');
      expect(BoardCategories.topicKey['정보공유'], 'info');
      expect(BoardCategories.topicKey['분실물'], 'lost');
      expect(BoardCategories.topicKey['학생회'], 'council');
      expect(BoardCategories.topicKey['동아리'], 'club');
    });

    test('topicKey에 전체/인기글 미포함', () {
      expect(BoardCategories.topicKey.containsKey('전체'), isFalse);
      expect(BoardCategories.topicKey.containsKey('인기글'), isFalse);
    });
  });

  group('color', () {
    test('각 카테고리별 색상 반환', () {
      expect(BoardCategories.color('자유'), AppColors.theme.primaryColor);
      expect(BoardCategories.color('질문'), AppColors.theme.secondaryColor);
      expect(BoardCategories.color('정보공유'), AppColors.theme.tertiaryColor);
      expect(BoardCategories.color('분실물'), const Color(0xFFFF5722));
      expect(BoardCategories.color('학생회'), const Color(0xFF4CAF50));
      expect(BoardCategories.color('동아리'), const Color(0xFF9C27B0));
    });

    test('알 수 없는 카테고리 → darkGrey', () {
      expect(BoardCategories.color('없는카테고리'), AppColors.theme.darkGreyColor);
      expect(BoardCategories.color(''), AppColors.theme.darkGreyColor);
    });
  });

  group('localizedName', () {
    testWidgets('한국어 로케일에서 이름 반환', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      expect(BoardCategories.localizedName(l, '전체'), '전체');
      expect(BoardCategories.localizedName(l, '자유'), '자유');
      expect(BoardCategories.localizedName(l, '질문'), '질문');
      expect(BoardCategories.localizedName(l, '정보공유'), '정보공유');
      expect(BoardCategories.localizedName(l, '분실물'), '분실물');
      expect(BoardCategories.localizedName(l, '학생회'), '학생회');
      expect(BoardCategories.localizedName(l, '동아리'), '동아리');
      expect(BoardCategories.localizedName(l, '인기글'), '인기글');
    });

    testWidgets('알 수 없는 키 → 키 자체 반환', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      expect(BoardCategories.localizedName(l, '없는키'), '없는키');
    });

    testWidgets('영어 로케일에서 이름 반환', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Builder(builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      // 영어 번역이 존재하는지 확인
      final name = BoardCategories.localizedName(l, '자유');
      expect(name, isNotEmpty);
    });
  });

  group('formatSuspendDuration', () {
    testWidgets('일/시간/분 조합', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      // 2일 3시간 15분
      final result = BoardCategories.formatSuspendDuration(
        l, const Duration(days: 2, hours: 3, minutes: 15));
      expect(result, contains('2'));
      expect(result, contains('3'));
      expect(result, contains('15'));
    });

    testWidgets('0초만 남은 경우', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      final result = BoardCategories.formatSuspendDuration(l, Duration.zero);
      expect(result, isNotEmpty); // "0초" 등
    });

    testWidgets('시간만 있는 경우', (tester) async {
      late AppLocalizations l;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Builder(builder: (context) {
          l = AppLocalizations.of(context)!;
          return const SizedBox();
        }),
      ));
      await tester.pumpAndSettle();

      final result = BoardCategories.formatSuspendDuration(
        l, const Duration(hours: 5));
      expect(result, contains('5'));
    });
  });
}
