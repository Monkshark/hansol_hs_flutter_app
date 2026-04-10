# Meal

> `lib/data/meal.dart` — 급식 데이터 모델 (freezed)

`@freezed` 기반 불변 데이터 클래스. JSON 직렬화(`meal.g.dart`), 동등성/copyWith(`meal.freezed.dart`)는 코드 생성으로 자동 처리.

---

## 필드

```dart
@freezed
class Meal with _$Meal {
  const factory Meal({
    required String? meal,      // 메뉴 텍스트 (줄바꿈 구분). null이면 급식 없음
    required DateTime date,     // 급식 날짜
    required int mealType,      // 1=조식, 2=중식, 3=석식
    required String kcal,       // 칼로리 (예: '823.4 Kcal')
    @Default('') String ntrInfo, // 영양정보 (탄수화물/단백질/지방 등, 줄바꿈 구분)
  }) = _Meal;
}
```

- `meal` 필드: NEIS API 응답의 `DDISH_NM`에서 `<br/>`을 `\n`으로 치환한 결과
- `ntrInfo` 필드: `NTR_INFO`에서 동일하게 치환. 없으면 빈 문자열

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

`mealType` 정수를 한국어 문자열로 변환. 급식 카드 UI에서 식사 유형 라벨에 사용.

---

## `toString`

```dart
@override
String toString() => meal ?? '';
```

`meal`이 null이면 빈 문자열. 디버그 출력 및 위젯 텍스트 바인딩에 활용.

---

## JSON 직렬화

```dart
factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
```

`_$MealFromJson`/`_$MealToJson`은 `meal.g.dart`에 자동 생성. `MealDataApi._saveToCache`/`_getFromCache`에서 SharedPreferences JSON 저장/복원에 사용.

---

## 사용처

| 위치 | 용도 |
|------|------|
| `MealDataApi.getMeal` | API 응답을 Meal 객체로 변환 후 반환 |
| `MealDataApi._saveToCache` | Meal을 JSON으로 직렬화해 SharedPreferences에 캐시 |
| `MealScreen` | Meal.meal을 줄바꿈 기준으로 split해 메뉴 리스트 표시 |
| `WidgetService.updateMealWidget` | Meal.meal에서 알레르기 정보 제거 후 홈 위젯에 전달 |
| [`DailyMealNotification`](../notification/daily_meal_notification.md) | Meal.meal을 한 줄로 합쳐 알림 본문에 사용 |
