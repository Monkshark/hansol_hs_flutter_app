import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

@freezed
class Meal with _$Meal {
  const Meal._();

  const factory Meal({
    required String? meal,
    required DateTime date,
    required int mealType,
    required String kcal,
    @Default('') String ntrInfo,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);

  @override
  String toString() => meal ?? '';

  String getMealTypeKey() {
    switch (mealType) {
      case 1: return 'breakfast';
      case 2: return 'lunch';
      case 3: return 'dinner';
      default: return 'lunch';
    }
  }
}
