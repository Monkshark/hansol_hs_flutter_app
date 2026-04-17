import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/dday_manager.dart';
import 'package:hansol_high_school/data/meal.dart';

final pinnedDDayProvider = FutureProvider.autoDispose<DDay?>((ref) {
  return DDayManager.getPinned();
});

final todayLunchProvider = FutureProvider.autoDispose<Meal?>((ref) {
  return MealDataApi.getMeal(
    date: DateTime.now(),
    mealType: MealDataApi.LUNCH,
    type: MealDataApi.MENU,
  );
});
