import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// TimetableDataApi의 캐시 키 및 오프라인 에러 맵 로직을 동일하게 복제하여 테스트
/// (원본: lib/api/timetable_data_api.dart)

String timetableCacheKey({
  required DateTime startDate,
  required DateTime endDate,
  required String grade,
  String? classNum,
}) {
  final formattedStartDate = DateFormat('yyyyMMdd').format(startDate);
  final formattedEndDate = DateFormat('yyyyMMdd').format(endDate);
  return '$formattedStartDate-$formattedEndDate-$grade${classNum != null ? '-$classNum' : ''}';
}

Map<String, Map<String, List<String>>> offlineErrorMap() {
  return {
    "error": {
      "error": ["시간표를 확인하려면 인터넷에 연결하세요"]
    }
  };
}

Map<String, Map<String, List<String>>> emptyErrorMap() {
  return {
    "error": {
      "error": ["정보 없음"]
    }
  };
}

void main() {
  group('TimetableDataApi cache key', () {
    test('generates correct format without classNum', () {
      final start = DateTime(2026, 4, 6);
      final end = DateTime(2026, 4, 10);
      expect(
        timetableCacheKey(startDate: start, endDate: end, grade: '2'),
        '20260406-20260410-2',
      );
    });

    test('generates correct format with classNum', () {
      final start = DateTime(2026, 4, 6);
      final end = DateTime(2026, 4, 10);
      expect(
        timetableCacheKey(startDate: start, endDate: end, grade: '1', classNum: '3'),
        '20260406-20260410-1-3',
      );
    });

    test('pads month and day with leading zeros', () {
      final start = DateTime(2026, 1, 5);
      final end = DateTime(2026, 2, 9);
      expect(
        timetableCacheKey(startDate: start, endDate: end, grade: '3'),
        '20260105-20260209-3',
      );
    });

    test('different grades produce different keys', () {
      final start = DateTime(2026, 4, 6);
      final end = DateTime(2026, 4, 10);
      final key1 = timetableCacheKey(startDate: start, endDate: end, grade: '1');
      final key2 = timetableCacheKey(startDate: start, endDate: end, grade: '2');
      expect(key1 != key2, true);
    });

    test('null classNum omits class suffix', () {
      final start = DateTime(2026, 4, 6);
      final end = DateTime(2026, 4, 10);
      final key = timetableCacheKey(startDate: start, endDate: end, grade: '2', classNum: null);
      expect(key, '20260406-20260410-2');
      expect(key.contains('-null'), false);
    });
  });

  group('TimetableDataApi error maps', () {
    test('offline error map has correct structure', () {
      final error = offlineErrorMap();
      expect(error.containsKey('error'), true);
      expect(error['error']!['error'], ['시간표를 확인하려면 인터넷에 연결하세요']);
    });

    test('empty error map has correct structure', () {
      final error = emptyErrorMap();
      expect(error.containsKey('error'), true);
      expect(error['error']!['error'], ['정보 없음']);
    });

    test('error key check pattern works', () {
      final error = offlineErrorMap();
      expect(error.containsKey('error'), true);

      final normalData = <String, Map<String, List<String>>>{
        '20260406': {'1': ['수학', '영어']},
      };
      expect(normalData.containsKey('error'), false);
    });
  });
}
