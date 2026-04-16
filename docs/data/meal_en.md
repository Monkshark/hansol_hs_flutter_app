# Meal

> 한국어: [meal.md](./meal.md)

> `lib/data/meal.dart` — Meal data model (freezed)

Immutable data class based on `@freezed`. JSON serialization (`meal.g.dart`) and equality/copyWith (`meal.freezed.dart`) are handled automatically by code generation.

---

## Fields

```dart
@freezed
class Meal with _$Meal {
  const factory Meal({
    required String? meal,      // Menu text (newline-separated). null means no meal
    required DateTime date,     // Meal date
    required int mealType,      // 1=breakfast, 2=lunch, 3=dinner
    required String kcal,       // Calories (e.g., '823.4 Kcal')
    @Default('') String ntrInfo, // Nutrition info (carbs/protein/fat, newline-separated)
  }) = _Meal;
}
```

- `meal` field: Result of replacing `<br/>` with `\n` in the `DDISH_NM` field of the NEIS API response
- `ntrInfo` field: Same replacement applied to `NTR_INFO`. Empty string if missing

---

## `getMealType`

```dart
String getMealType() {
  switch (mealType) {
    case 1: return '조식';
    case 2: return '중식';
    case 3: return '석식';
    default: return '중식';
  }
}
```

Converts the `mealType` integer into a Korean string. Used as the meal type label in the meal card UI.

---

## `toString`

```dart
@override
String toString() => meal ?? '';
```

Returns an empty string when `meal` is null. Used for debug output and widget text binding.

---

## JSON serialization

```dart
factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
```

`_$MealFromJson`/`_$MealToJson` are auto-generated in `meal.g.dart`. Used by `MealDataApi._saveToCache`/`_getFromCache` for SharedPreferences JSON save/restore.

---

## Usage

| Location | Purpose |
|----------|---------|
| [`MealDataApi`](../api/meal_data_api.md)`.getMeal` | Converts API response into Meal objects and returns them |
| [`MealDataApi`](../api/meal_data_api.md)`._saveToCache` | Serializes Meal as JSON and caches it in SharedPreferences |
| `MealScreen` | Splits Meal.meal by newline to display the menu list |
| `WidgetService.updateMealWidget` | Strips allergy info from Meal.meal before passing to the home widget |
| [`DailyMealNotification`](../notification/daily_meal_notification.md) | Joins Meal.meal into a single line for the notification body |
