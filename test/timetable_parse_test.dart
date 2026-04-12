import 'package:flutter_test/flutter_test.dart';

/// TimetableDataApi._processTimetable 순수 로직 복제
Map<String, Map<String, List<String>>> processTimetable(
    List<dynamic> timetableArray) {
  Map<String, Map<String, List<String>>> resultMap = {};
  for (var data in timetableArray) {
    final rowArray = data['row'] as List<dynamic>?;
    if (rowArray == null) continue;
    for (var item in rowArray) {
      final rawClassNum = item['CLASS_NM'];
      final date = item['ALL_TI_YMD'] as String?;
      final content = item['ITRT_CNTNT'] as String?;
      final perio = int.tryParse(item['PERIO']?.toString() ?? '');
      if (date == null || content == null || perio == null) continue;

      final classNum = rawClassNum?.toString() ?? 'special';
      final dayMap = resultMap.putIfAbsent(date, () => {});
      final classList = dayMap.putIfAbsent(classNum, () => []);

      while (classList.length < perio) {
        classList.add('');
      }
      classList[perio - 1] = content;
    }
  }
  return resultMap;
}

/// TimetableDataApi._hasData 순수 로직 복제
bool hasData(Map<String, Map<String, List<String>>> timetable) {
  if (timetable.containsKey('error')) return false;
  return timetable.values
      .any((classMap) => classMap.values.any((subjects) => subjects.isNotEmpty));
}

/// MealDataApi._cacheKey 순수 로직 복제
String mealCacheKey(DateTime date, int mealType) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return 'meal_$y$m${d}_$mealType';
}

void main() {
  group('processTimetable', () {
    test('parses basic timetable', () {
      final data = [
        {
          'row': [
            {'CLASS_NM': '3', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '국어', 'PERIO': '1'},
            {'CLASS_NM': '3', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '수학', 'PERIO': '2'},
          ]
        }
      ];
      final result = processTimetable(data);
      expect(result['20260413']!['3']![0], '국어');
      expect(result['20260413']!['3']![1], '수학');
    });

    test('handles multiple dates', () {
      final data = [
        {
          'row': [
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '국어', 'PERIO': '1'},
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260414', 'ITRT_CNTNT': '영어', 'PERIO': '1'},
          ]
        }
      ];
      final result = processTimetable(data);
      expect(result.keys.length, 2);
      expect(result['20260413']!['1']![0], '국어');
      expect(result['20260414']!['1']![0], '영어');
    });

    test('handles multiple classes', () {
      final data = [
        {
          'row': [
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '국어', 'PERIO': '1'},
            {'CLASS_NM': '2', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '수학', 'PERIO': '1'},
          ]
        }
      ];
      final result = processTimetable(data);
      expect(result['20260413']!['1']![0], '국어');
      expect(result['20260413']!['2']![0], '수학');
    });

    test('pads empty periods', () {
      final data = [
        {
          'row': [
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '체육', 'PERIO': '3'},
          ]
        }
      ];
      final result = processTimetable(data);
      final subjects = result['20260413']!['1']!;
      expect(subjects.length, 3);
      expect(subjects[0], '');
      expect(subjects[1], '');
      expect(subjects[2], '체육');
    });

    test('null CLASS_NM becomes special', () {
      final data = [
        {
          'row': [
            {'CLASS_NM': null, 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '자습', 'PERIO': '1'},
          ]
        }
      ];
      final result = processTimetable(data);
      expect(result['20260413']!['special']![0], '자습');
    });

    test('skips entries without row', () {
      final data = [
        {'head': [{'count': 10}]},
        {
          'row': [
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '국어', 'PERIO': '1'},
          ]
        }
      ];
      final result = processTimetable(data);
      expect(result['20260413']!['1']![0], '국어');
    });

    test('skips entries with null required fields', () {
      final data = [
        {
          'row': [
            {'CLASS_NM': '1', 'ALL_TI_YMD': null, 'ITRT_CNTNT': '국어', 'PERIO': '1'},
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': null, 'PERIO': '1'},
            {'CLASS_NM': '1', 'ALL_TI_YMD': '20260413', 'ITRT_CNTNT': '국어', 'PERIO': null},
          ]
        }
      ];
      final result = processTimetable(data);
      expect(result, isEmpty);
    });

    test('empty array returns empty map', () {
      expect(processTimetable([]), isEmpty);
    });
  });

  group('hasData', () {
    test('returns false for error key', () {
      expect(hasData({'error': {'error': []}}), false);
    });

    test('returns false for empty timetable', () {
      expect(hasData({}), false);
    });

    test('returns false for empty subjects', () {
      expect(hasData({'20260413': {'1': []}}), false);
    });

    test('returns true for valid data', () {
      expect(
        hasData({
          '20260413': {
            '1': ['국어', '수학']
          }
        }),
        true,
      );
    });
  });

  group('mealCacheKey', () {
    test('generates correct format', () {
      expect(mealCacheKey(DateTime(2026, 4, 12), 1), 'meal_20260412_1');
      expect(mealCacheKey(DateTime(2026, 4, 12), 2), 'meal_20260412_2');
      expect(mealCacheKey(DateTime(2026, 4, 12), 3), 'meal_20260412_3');
    });

    test('pads single digit month and day', () {
      expect(mealCacheKey(DateTime(2026, 1, 5), 2), 'meal_20260105_2');
    });

    test('different dates produce different keys', () {
      final k1 = mealCacheKey(DateTime(2026, 4, 1), 1);
      final k2 = mealCacheKey(DateTime(2026, 4, 2), 1);
      expect(k1 != k2, true);
    });

    test('different meal types produce different keys', () {
      final k1 = mealCacheKey(DateTime(2026, 4, 12), 1);
      final k2 = mealCacheKey(DateTime(2026, 4, 12), 2);
      expect(k1 != k2, true);
    });
  });
}
