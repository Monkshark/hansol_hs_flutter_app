# WidgetService

> `lib/widgets/home_widget/widget_service.dart` — 홈 화면 위젯 데이터 갱신

`home_widget` 패키지를 사용해 Android/iOS 홈 화면 위젯에 급식/시간표 데이터를 전달한다.

---

## `initialize`

```dart
static Future<void> initialize()
```

App Group ID를 설정한다 (`group.com.monkshark.hansol_high_school`). iOS 위젯 공유에 필요.

---

## `updateAll`

```dart
static Future<void> updateAll()
```

급식 + 시간표 위젯을 병렬로 갱신:
```dart
await Future.wait([updateMealWidget(), updateTimetableWidget()]);
```

---

## `updateMealWidget`

```dart
static Future<void> updateMealWidget()
```

**설명**: 오늘의 급식 데이터를 위젯에 전달한다.

1. 조식/중식/석식 병렬 조회:
   ```dart
   final meals = await Future.wait([
     MealDataApi.getMeal(date: now, mealType: MealDataApi.BREAKFAST, ...),
     MealDataApi.getMeal(date: now, mealType: MealDataApi.LUNCH, ...),
     MealDataApi.getMeal(date: now, mealType: MealDataApi.DINNER, ...),
   ]);
   ```

2. 알레르기 정보 제거 후 위젯 데이터 저장:
   ```dart
   await HomeWidget.saveWidgetData<String>('meal_date', dateStr);
   await HomeWidget.saveWidgetData<String>('meal_breakfast', breakfast);
   await HomeWidget.saveWidgetData<String>('meal_lunch', lunch);
   await HomeWidget.saveWidgetData<String>('meal_dinner', dinner);
   ```

3. Android 위젯 갱신 트리거:
   ```dart
   await HomeWidget.updateWidget(androidName: 'MealWidgetProvider');
   await HomeWidget.updateWidget(androidName: 'CombinedWidgetProvider');
   ```

---

## `updateTimetableWidget`

```dart
static Future<void> updateTimetableWidget()
```

**설명**: 오늘의 시간표 데이터를 위젯에 전달한다.

1. 학년/반 미설정 시 안내 메시지:
   ```dart
   if (grade == 0 || classNum == 0) {
     await HomeWidget.saveWidgetData<String>('timetable_date', '학년/반을 설정해주세요');
   }
   ```

2. SharedPreferences에서 시간표 그리드 읽기:
   ```dart
   final gridData = prefs.getStringList('widget_timetable_grid');
   final daySubjects = gridData[weekday - 1].split(',');
   ```

3. 뒤에서부터 빈 교시 제거 후 위젯 데이터 저장:
   ```dart
   while (subjects.isNotEmpty && subjects.last.isEmpty) {
     subjects.removeLast();
   }
   await HomeWidget.saveWidgetData<String>('timetable_data', subjects.join(','));
   await HomeWidget.saveWidgetData<int>('timetable_current', _getCurrentPeriod(now));
   ```

---

## `_cleanMealText`

```dart
static String _cleanMealText(String? text)
```

급식 없음/오프라인 → `'정보 없음'`. 알레르기 번호 제거: `replaceAll(RegExp(r'\s*\([\d.]+\)'), '')`.

---

## `_getCurrentPeriod`

```dart
static int _getCurrentPeriod(DateTime now)
```

**설명**: 현재 교시를 계산한다.

```dart
const starts = [500, 560, 620, 680, 750, 810, 870];  // 08:20, 09:20, ...
const ends = [550, 610, 670, 740, 800, 860, 920];     // 09:10, 10:10, ...
```

- 수업 시간 내 → 해당 교시 번호 (1~7)
- 마지막 수업 후 → -1
- 수업 전 → 0

---

## `widgetBackgroundCallback`

```dart
@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  await WidgetService.initialize();
  await WidgetService.updateAll();
}
```

홈 위젯 인터랙션 콜백. 위젯 탭/자정 알람에서 데이터 갱신 트리거.
