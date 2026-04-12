import 'package:flutter_test/flutter_test.dart';

/// WidgetService._cleanMealText 순수 로직 복제
String cleanMealText(String? text, String fallback) {
  if (text == null || text.isEmpty) return fallback;
  return text
      .replaceAll(RegExp(r'\s*\([\d.]+\)'), '')
      .replaceAll(RegExp(r'\s*<[\d.]+>'), '');
}

/// WidgetService._getCurrentPeriod 순수 로직 복제
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
    test('removes nutritional info in parentheses', () {
      expect(cleanMealText('쌀밥 (5.0)', 'N/A'), '쌀밥');
      expect(cleanMealText('된장국 (1.5.6)', 'N/A'), '된장국');
    });

    test('removes nutritional info in angle brackets', () {
      expect(cleanMealText('김치 <1.5>', 'N/A'), '김치');
    });

    test('removes multiple nutritional markers', () {
      expect(
        cleanMealText('쌀밥 (5.0)\n된장국 (1.5.6)\n김치 (9.13)', 'N/A'),
        '쌀밥\n된장국\n김치',
      );
    });

    test('returns fallback for null', () {
      expect(cleanMealText(null, '정보 없음'), '정보 없음');
    });

    test('returns fallback for empty string', () {
      expect(cleanMealText('', '정보 없음'), '정보 없음');
    });

    test('returns text as-is if no markers', () {
      expect(cleanMealText('쌀밥', 'N/A'), '쌀밥');
    });
  });

  group('getCurrentPeriod', () {
    test('before school returns 0', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 7, 0)), 0);
    });

    test('1st period (8:20-9:10)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 8, 20)), 1);
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 9, 0)), 1);
    });

    test('2nd period (9:20-10:10)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 9, 20)), 2);
    });

    test('3rd period (10:20-11:10)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 10, 20)), 3);
    });

    test('4th period (11:20-12:20)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 11, 20)), 4);
    });

    test('5th period (12:30-13:20)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 12, 30)), 5);
    });

    test('6th period (13:30-14:20)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 13, 30)), 6);
    });

    test('7th period (14:30-15:20)', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 14, 30)), 7);
    });

    test('after school returns -1', () {
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 15, 20)), -1);
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 18, 0)), -1);
    });

    test('between periods returns 0', () {
      // 9:10-9:20 break between 1st and 2nd
      expect(getCurrentPeriod(DateTime(2026, 4, 12, 9, 10)), 0);
    });
  });
}
