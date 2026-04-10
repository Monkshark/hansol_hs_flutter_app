# DailyMealNotification

> `lib/notification/daily_meal_notification.dart` — 로컬 급식 알림 스케줄링

인스턴스 메서드. 조식/중식/석식 평일 반복 알림을 `flutter_local_notifications` + `timezone`으로 스케줄링.

---

## `initializeNotifications`

```dart
Future<void> initializeNotifications()
```

**설명**: 로컬 알림 플러그인을 초기화한다.

1. Android/iOS 초기화 설정:
   ```dart
   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
   final iosSettings = DarwinInitializationSettings(...);
   ```

2. 알림 탭 콜백 등록:
   ```dart
   await _localNotificationsPlugin.initialize(
     InitializationSettings(...),
     onDidReceiveNotificationResponse: _onNotificationTap,
     onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
   );
   ```

3. 플랫폼별 권한 요청:
   ```dart
   if (Platform.isIOS) { ... requestPermissions(...) }
   else if (Platform.isAndroid) { await Permission.notification.request(); }
   ```

---

## `scheduleDailyNotifications`

```dart
Future<void> scheduleDailyNotifications()
```

**설명**: [SettingData](../data/setting_data.md) 설정에 따라 평일(월~금) 반복 알림을 등록한다.

```dart
if (settings.isBreakfastNotificationOn) {
  await _scheduleWeeklyNotification(id: 1, mealLabel: '조식', time: ...);
}
if (settings.isLunchNotificationOn) {
  await _scheduleWeeklyNotification(id: 2, mealLabel: '중식', time: ...);
}
if (settings.isDinnerNotificationOn) {
  await _scheduleWeeklyNotification(id: 3, mealLabel: '석식', time: ...);
}
```

기존 알림을 모두 취소 후 재등록 (`cancelAllNotifications` 먼저 호출).

---

## `_scheduleWeeklyNotification`

```dart
Future<void> _scheduleWeeklyNotification({
  required int id, required String mealLabel,
  required TimeOfDay time, required List<int> weekdays,
})
```

**설명**: 특정 식사의 요일별 반복 알림을 등록한다.

1. 오늘의 급식 메뉴를 미리 조회해 알림 본문에 포함:
   ```dart
   final meal = await MealDataApi.getMeal(date: DateTime.now(), mealType: mealType, ...);
   menuPreview = _cleanMenu(meal?.meal);
   ```

2. 월~금 각 요일에 대해 개별 알림 등록:
   ```dart
   for (int weekday in weekdays) {
     final notificationId = id * 10 + weekday;  // 예: 중식+화요일 = 22
     await _localNotificationsPlugin.zonedSchedule(
       notificationId, ...,
       matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,  // 매주 반복
     );
   }
   ```

3. `BigTextStyleInformation`으로 메뉴 미리보기 표시.

---

## `sendTestNotification`

```dart
Future<void> sendTestNotification()
```

5초 후 테스트 알림 전송. 알림 설정 화면에서 "테스트 알림 보내기" 버튼에 연결.

---

## `updateNotifications`

```dart
Future<void> updateNotifications()
```

설정 변경 시 호출. `cancelAllNotifications()` + `scheduleDailyNotifications()`.

---

## `_cleanMenu`

```dart
String _cleanMenu(String? menu)
```

급식 메뉴에서 알레르기 정보 번호를 제거하고 한 줄로 합침:

```dart
menu.split('\n')
    .map((e) => e.replaceAll(RegExp(r'\([0-9.,\s]+\)'), '').trim())
    .where((e) => e.isNotEmpty)
    .join(' · ');
// "치킨까스 (1.2.5) \n 된장국 (5.6)" → "치킨까스 · 된장국"
```

---

## 내부 유틸리티

| 함수 | 설명 |
|------|------|
| `_parseTimeOfDay(timeString)` | `'12:00'` → `TimeOfDay(hour: 12, minute: 0)` |
| `_nextInstanceOfWeekday(time, weekday)` | 다음 해당 요일+시간의 `TZDateTime` 계산 |
| `_nextInstanceOfTime(timeOfDay)` | 오늘/내일 중 해당 시간이 미래인 `TZDateTime` |
