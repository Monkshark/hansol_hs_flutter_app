import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/meal.dart';
import 'package:hansol_high_school/data/subject.dart';

void main() {
  group('Meal.getMealTypeKey', () {
    test('returns breakfast for 1', () {
      final meal = Meal(meal: '밥', date: DateTime(2026, 4, 12), mealType: 1, kcal: '500');
      expect(meal.getMealTypeKey(), 'breakfast');
    });

    test('returns lunch for 2', () {
      final meal = Meal(meal: '밥', date: DateTime(2026, 4, 12), mealType: 2, kcal: '700');
      expect(meal.getMealTypeKey(), 'lunch');
    });

    test('returns dinner for 3', () {
      final meal = Meal(meal: '밥', date: DateTime(2026, 4, 12), mealType: 3, kcal: '600');
      expect(meal.getMealTypeKey(), 'dinner');
    });

    test('returns lunch for unknown type', () {
      final meal = Meal(meal: '밥', date: DateTime(2026, 4, 12), mealType: 99, kcal: '');
      expect(meal.getMealTypeKey(), 'lunch');
    });
  });

  group('Meal serialization', () {
    test('toJson and fromJson roundtrip', () {
      final original = Meal(
        meal: '쌀밥\n된장국\n김치',
        date: DateTime(2026, 4, 12),
        mealType: 2,
        kcal: '650.3 Kcal',
        ntrInfo: '탄수화물: 100g',
      );
      final json = original.toJson();
      final restored = Meal.fromJson(json);
      expect(restored.meal, original.meal);
      expect(restored.mealType, 2);
      expect(restored.kcal, '650.3 Kcal');
      expect(restored.ntrInfo, '탄수화물: 100g');
    });

    test('null meal is preserved', () {
      final meal = Meal(meal: null, date: DateTime(2026, 4, 12), mealType: 1, kcal: '');
      final restored = Meal.fromJson(meal.toJson());
      expect(restored.meal, null);
    });

    test('default ntrInfo is empty string', () {
      final meal = Meal(meal: '밥', date: DateTime(2026, 4, 12), mealType: 1, kcal: '');
      expect(meal.ntrInfo, '');
    });

    test('toString returns meal text', () {
      final meal = Meal(meal: '쌀밥', date: DateTime(2026, 4, 12), mealType: 1, kcal: '');
      expect(meal.toString(), '쌀밥');
    });

    test('toString returns empty for null meal', () {
      final meal = Meal(meal: null, date: DateTime(2026, 4, 12), mealType: 1, kcal: '');
      expect(meal.toString(), '');
    });
  });

  group('Subject equality', () {
    test('same name and class are equal', () {
      const a = Subject(subjectName: '국어', subjectClass: 1);
      const b = Subject(subjectName: '국어', subjectClass: 1);
      expect(a == b, true);
      expect(a.hashCode, b.hashCode);
    });

    test('different name are not equal', () {
      const a = Subject(subjectName: '국어', subjectClass: 1);
      const b = Subject(subjectName: '수학', subjectClass: 1);
      expect(a == b, false);
    });

    test('different class are not equal', () {
      const a = Subject(subjectName: '국어', subjectClass: 1);
      const b = Subject(subjectName: '국어', subjectClass: 2);
      expect(a == b, false);
    });

    test('category and isOriginal do not affect equality', () {
      const a = Subject(subjectName: '국어', subjectClass: 1, category: 'A', isOriginal: true);
      const b = Subject(subjectName: '국어', subjectClass: 1, category: 'B', isOriginal: false);
      expect(a == b, true);
    });

    test('works in Set for deduplication', () {
      final set = <Subject>{};
      set.add(const Subject(subjectName: '국어', subjectClass: 1));
      set.add(const Subject(subjectName: '국어', subjectClass: 1));
      set.add(const Subject(subjectName: '수학', subjectClass: 2));
      expect(set.length, 2);
    });
  });

  group('Subject serialization', () {
    test('toJson and fromJson roundtrip', () {
      const original = Subject(
        subjectName: '국어',
        subjectClass: 3,
        category: '공통',
        isOriginal: true,
      );
      final json = original.toJson();
      final restored = Subject.fromJson(json);
      expect(restored.subjectName, '국어');
      expect(restored.subjectClass, 3);
      expect(restored.category, '공통');
      expect(restored.isOriginal, true);
    });

    test('default isOriginal is false', () {
      const subject = Subject(subjectName: '수학', subjectClass: 1);
      expect(subject.isOriginal, false);
    });

    test('default category is null', () {
      const subject = Subject(subjectName: '수학', subjectClass: 1);
      expect(subject.category, null);
    });
  });
}
