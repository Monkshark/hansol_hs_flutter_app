import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// MealDataApi._cacheKey 로직을 동일하게 복제하여 테스트
/// (원본: lib/api/meal_data_api.dart)

String cacheKey(DateTime date, int mealType) {
  return 'meal_${DateFormat('yyyyMMdd').format(date)}_$mealType';
}

void main() {
  group('MealDataApi cache key', () {
    test('generates correct format for lunch', () {
      final date = DateTime(2026, 4, 1);
      expect(cacheKey(date, 2), 'meal_20260401_2');
    });

    test('generates correct format for breakfast', () {
      final date = DateTime(2026, 12, 25);
      expect(cacheKey(date, 1), 'meal_20261225_1');
    });

    test('generates correct format for dinner', () {
      final date = DateTime(2026, 1, 5);
      expect(cacheKey(date, 3), 'meal_20260105_3');
    });

    test('pads month and day with leading zeros', () {
      final date = DateTime(2026, 3, 9);
      expect(cacheKey(date, 2), 'meal_20260309_2');
    });

    test('different dates produce different keys', () {
      final date1 = DateTime(2026, 4, 1);
      final date2 = DateTime(2026, 4, 2);
      expect(cacheKey(date1, 2) != cacheKey(date2, 2), true);
    });

    test('different meal types produce different keys', () {
      final date = DateTime(2026, 4, 1);
      expect(cacheKey(date, 1) != cacheKey(date, 2), true);
      expect(cacheKey(date, 2) != cacheKey(date, 3), true);
    });
  });
}
