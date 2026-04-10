import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/meal.dart';

void main() {
  group('Meal', () {
    test('toJson and fromJson roundtrip', () {
      final meal = Meal(
        meal: '김치볶음밥\n된장찌개',
        date: DateTime(2026, 4, 1),
        mealType: 2,
        kcal: '650 Kcal',
      );

      final json = meal.toJson();
      final restored = Meal.fromJson(json);

      expect(restored.meal, '김치볶음밥\n된장찌개');
      expect(restored.date.year, 2026);
      expect(restored.mealType, 2);
      expect(restored.kcal, '650 Kcal');
    });

    test('getMealTypeKey returns correct key', () {
      expect(Meal(meal: '', date: DateTime.now(), mealType: 1, kcal: '').getMealTypeKey(), 'breakfast');
      expect(Meal(meal: '', date: DateTime.now(), mealType: 2, kcal: '').getMealTypeKey(), 'lunch');
      expect(Meal(meal: '', date: DateTime.now(), mealType: 3, kcal: '').getMealTypeKey(), 'dinner');
      expect(Meal(meal: '', date: DateTime.now(), mealType: 99, kcal: '').getMealTypeKey(), 'lunch');
    });

    test('toString returns meal content', () {
      final meal = Meal(meal: '비빔밥', date: DateTime.now(), mealType: 2, kcal: '');
      expect(meal.toString(), '비빔밥');
    });

    test('null meal toString returns empty', () {
      final meal = Meal(meal: null, date: DateTime.now(), mealType: 2, kcal: '');
      expect(meal.toString(), '');
    });
  });
}
