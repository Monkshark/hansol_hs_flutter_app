# SettingData

> 한국어: [setting_data.md](./setting_data.md)

> `lib/data/setting_data.dart` — SharedPreferences settings singleton

Singleton class that manages app-wide settings through SharedPreferences.

---

## Singleton pattern

```dart
static final SettingData _instance = SettingData._internal();
factory SettingData() => _instance;
```

`SettingData()` provides access to the same instance from anywhere.

---

## `init`

```dart
Future<void> init()
```

Called once at the start of `main()`. Caches the result of `SharedPreferences.getInstance()` internally.

---

## Grade/class settings

| Property | SharedPreferences key | Default |
|----------|----------------------|---------|
| `grade` (get/set) | `'Grade'` | 0 |
| `classNum` (get/set) | `'Class'` | 0 |
| `isGradeSet` (get) | — | `grade > 0 && classNum > 0` |

---

## Theme settings

| Property | Key | Default | Description |
|----------|-----|---------|-------------|
| `isDarkMode` | `'isDarkMode'` | false | Legacy (superseded by themeModeIndex) |
| `themeModeIndex` | `'themeModeIndex'` | 2 | 0=light, 1=dark, 2=system |

---

## Notification settings

| Property | Key | Default |
|----------|-----|---------|
| `isBreakfastNotificationOn` | `'isBreakfastNotificationOn'` | true |
| `breakfastTime` | `'breakfastTime'` | `'06:30'` |
| `isLunchNotificationOn` | `'isLunchNotificationOn'` | true |
| `lunchTime` | `'lunchTime'` | `'12:00'` |
| `isDinnerNotificationOn` | `'isDinnerNotificationOn'` | true |
| `dinnerTime` | `'dinnerTime'` | `'17:00'` |
| `isBoardNotificationOn` | `'isBoardNotificationOn'` | true |

---

## Generic accessors

```dart
bool getBool(String key, {bool defaultValue = false})
void setBool(String key, bool value)
```

Used for dynamic keys such as per-category notification toggles. Example: `getBool('noti_board_자유', defaultValue: true)`.
