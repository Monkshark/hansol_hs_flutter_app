import 'package:flutter_test/flutter_test.dart';

/// WidgetService의 private 헬퍼 로직을 동일하게 복제하여 테스트
/// (원본: lib/widgets/home_widget/widget_service.dart)

String cleanMealText(String? text) {
  if (text == null ||
      text.isEmpty ||
      text.contains('급식 정보가 없습니다') ||
      text.contains('인터넷')) {
    return '정보 없음';
  }
  return text
      .replaceAll(RegExp(r'\s*\([\d.]+\)'), '')
      .replaceAll(RegExp(r'\s*<[\d.]+>'), '');
}

int getCurrentPeriod(DateTime now) {
  final minutes = now.hour * 60 + now.minute;
  const starts = [500, 560, 620, 680, 750, 810, 870];
  const ends = [550, 610, 670, 740, 800, 860, 920];

  for (int i = 0; i < starts.length; i++) {
    if (minutes >= starts[i] && minutes < ends[i]) return i + 1;
  }
  if (minutes >= ends.last) return -1;
  return 0;
}

void main() {
  group('cleanMealText', () {
    test('returns 정보 없음 for null input', () {
      expect(cleanMealText(null), '정보 없음');
    });

    test('returns 정보 없음 for empty string', () {
      expect(cleanMealText(''), '정보 없음');
    });

    test('returns 정보 없음 when text contains 급식 정보가 없습니다', () {
      expect(cleanMealText('급식 정보가 없습니다.'), '정보 없음');
      expect(cleanMealText('급식 정보가 없습니다'), '정보 없음');
    });

    test('returns 정보 없음 when text contains 인터넷', () {
      expect(cleanMealText('식단 정보를 확인하려면 인터넷에 연결하세요'), '정보 없음');
    });

    test('removes allergen info in parentheses', () {
      expect(cleanMealText('치킨까스 (1.2.5.6)'), '치킨까스');
    });

    test('removes allergen info in angle brackets', () {
      expect(cleanMealText('비빔밥 <1.5.6>'), '비빔밥');
    });

    test('removes multiple allergen annotations', () {
      expect(
        cleanMealText('김치볶음밥 (1.2)\n된장찌개 (5.6.9)'),
        '김치볶음밥\n된장찌개',
      );
    });

    test('returns text as-is when no allergens present', () {
      expect(cleanMealText('흰쌀밥\n김치'), '흰쌀밥\n김치');
    });
  });

  group('getCurrentPeriod', () {
    test('returns 0 before school (early morning)', () {
      final early = DateTime(2026, 4, 6, 7, 0); // 07:00 = 420 min
      expect(getCurrentPeriod(early), 0);
    });

    test('returns 1 during first period (08:20~09:10)', () {
      final during1 = DateTime(2026, 4, 6, 8, 30); // 510 min
      expect(getCurrentPeriod(during1), 1);
    });

    test('returns 2 during second period (09:20~10:10)', () {
      final during2 = DateTime(2026, 4, 6, 9, 25); // 565 min
      expect(getCurrentPeriod(during2), 2);
    });

    test('returns 3 during third period (10:20~11:10)', () {
      final during3 = DateTime(2026, 4, 6, 10, 30); // 630 min
      expect(getCurrentPeriod(during3), 3);
    });

    test('returns 4 during fourth period (11:20~12:20)', () {
      final during4 = DateTime(2026, 4, 6, 11, 30); // 690 min
      expect(getCurrentPeriod(during4), 4);
    });

    test('returns 5 during fifth period (12:30~13:20)', () {
      final during5 = DateTime(2026, 4, 6, 12, 35); // 755 min
      expect(getCurrentPeriod(during5), 5);
    });

    test('returns 6 during sixth period (13:30~14:20)', () {
      final during6 = DateTime(2026, 4, 6, 13, 35); // 815 min
      expect(getCurrentPeriod(during6), 6);
    });

    test('returns 7 during seventh period (14:30~15:20)', () {
      final during7 = DateTime(2026, 4, 6, 14, 35); // 875 min
      expect(getCurrentPeriod(during7), 7);
    });

    test('returns 0 between periods (break time)', () {
      // Between period 1 (ends 550) and period 2 (starts 560) → 09:10~09:20
      final breakTime = DateTime(2026, 4, 6, 9, 15); // 555 min
      expect(getCurrentPeriod(breakTime), 0);
    });

    test('returns -1 after all periods end', () {
      final afterSchool = DateTime(2026, 4, 6, 16, 0); // 960 min
      expect(getCurrentPeriod(afterSchool), -1);
    });

    test('returns -1 exactly at last period end time', () {
      // ends.last = 920 = 15:20
      final exactEnd = DateTime(2026, 4, 6, 15, 20); // 920 min
      expect(getCurrentPeriod(exactEnd), -1);
    });

    test('returns period at exact start time', () {
      // starts[0] = 500 = 08:20
      final exactStart = DateTime(2026, 4, 6, 8, 20); // 500 min
      expect(getCurrentPeriod(exactStart), 1);
    });
  });
}
