# DailyMealNotification

> 한국어: [daily_meal_notification.md](./daily_meal_notification.md)

> `lib/notification/daily_meal_notification.dart` — Local meal notification scheduling

Instance methods. Schedules weekday-repeating notifications for breakfast/lunch/dinner using `flutter_local_notifications` + `timezone`. Looks up the menu via [`MealDataApi`](../api/meal_data_api.md) and includes it in the notification body.

---

## `initializeNotifications`

```dart
Future<void> initializeNotifications()
```

**Description**: Initializes the local notifications plugin.

1. Android/iOS initialization settings:
   ```dart
   const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
   final iosSettings = DarwinInitializationSettings(...);
   ```

2. Register the notification tap callback:
   ```dart
   await _localNotificationsPlugin.initialize(
     InitializationSettings(...),
     onDidReceiveNotificationResponse: _onNotificationTap,
     onDidReceiveBackgroundNotificationResponse: _onBackgroundNotification,
   );
   ```

3. Per-platform permission requests:
   ```dart
   if (Platform.isIOS) { ... requestPermissions(...) }
   else if (Platform.isAndroid) { await Permission.notification.request(); }
   ```

---

## `scheduleDailyNotifications`

```dart
Future<void> scheduleDailyNotifications()
```

**Description**: Registers weekday (Mon–Fri) repeating notifications according to the [SettingData](../data/setting_data.md) configuration.

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

Cancels all existing notifications before re-registering (calls `cancelAllNotifications` first).

---

## `_scheduleWeeklyNotification`

```dart
Future<void> _scheduleWeeklyNotification({
  required int id, required String mealLabel,
  required TimeOfDay time, required List<int> weekdays,
})
```

**Description**: Registers weekday-repeating notifications for a specific meal.

1. Pre-fetches today's meal menu to include in the notification body:
   ```dart
   final meal = await MealDataApi.getMeal(date: DateTime.now(), mealType: mealType, ...);
   menuPreview = _cleanMenu(meal?.meal);
   ```

2. Register an individual notification for each weekday Mon–Fri:
   ```dart
   for (int weekday in weekdays) {
     final notificationId = id * 10 + weekday;  // e.g., lunch + Tuesday = 22
     await _localNotificationsPlugin.zonedSchedule(
       notificationId, ...,
       matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,  // weekly repeat
     );
   }
   ```

3. Shows the menu preview via `BigTextStyleInformation`.

---

## `sendTestNotification`

```dart
Future<void> sendTestNotification()
```

Sends a test notification after 5 seconds. Wired to the "Send test notification" button on the notification settings screen.

---

## `updateNotifications`

```dart
Future<void> updateNotifications()
```

Called when settings change. `cancelAllNotifications()` + `scheduleDailyNotifications()`.

---

## `_cleanMenu`

```dart
String _cleanMenu(String? menu)
```

Strips allergy info numbers from the meal menu and joins it into a single line:

```dart
menu.split('\n')
    .map((e) => e.replaceAll(RegExp(r'\([0-9.,\s]+\)'), '').trim())
    .where((e) => e.isNotEmpty)
    .join(' · ');
// "치킨까스 (1.2.5) \n 된장국 (5.6)" → "치킨까스 · 된장국"
```

---

## Internal utilities

| Function | Description |
|----------|-------------|
| `_parseTimeOfDay(timeString)` | `'12:00'` → `TimeOfDay(hour: 12, minute: 0)` |
| `_nextInstanceOfWeekday(time, weekday)` | Computes the `TZDateTime` for the next matching weekday + time |
| `_nextInstanceOfTime(timeOfDay)` | The `TZDateTime` for today/tomorrow where the given time is still in the future |
