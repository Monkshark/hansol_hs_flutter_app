# SettingData

> `lib/data/setting_data.dart` — SharedPreferences 설정 싱글톤

앱 전체 설정을 SharedPreferences로 관리하는 싱글턴 클래스.

---

## 싱글턴 패턴

```dart
static final SettingData _instance = SettingData._internal();
factory SettingData() => _instance;
```

`SettingData()`로 어디서든 같은 인스턴스 접근.

---

## `init`

```dart
Future<void> init()
```

`main()` 시작 시 한 번 호출. `SharedPreferences.getInstance()` 결과를 내부에 캐시.

---

## 학년/반 설정

| 프로퍼티 | SharedPreferences 키 | 기본값 |
|----------|---------------------|--------|
| `grade` (get/set) | `'Grade'` | 0 |
| `classNum` (get/set) | `'Class'` | 0 |
| `isGradeSet` (get) | — | `grade > 0 && classNum > 0` |

---

## 테마 설정

| 프로퍼티 | 키 | 기본값 | 설명 |
|----------|----|--------|------|
| `isDarkMode` | `'isDarkMode'` | false | 레거시 (themeModeIndex로 대체) |
| `themeModeIndex` | `'themeModeIndex'` | 2 | 0=라이트, 1=다크, 2=시스템 |

---

## 알림 설정

| 프로퍼티 | 키 | 기본값 |
|----------|----|--------|
| `isBreakfastNotificationOn` | `'isBreakfastNotificationOn'` | true |
| `breakfastTime` | `'breakfastTime'` | `'06:30'` |
| `isLunchNotificationOn` | `'isLunchNotificationOn'` | true |
| `lunchTime` | `'lunchTime'` | `'12:00'` |
| `isDinnerNotificationOn` | `'isDinnerNotificationOn'` | true |
| `dinnerTime` | `'dinnerTime'` | `'17:00'` |
| `isBoardNotificationOn` | `'isBoardNotificationOn'` | true |

---

## 범용 접근자

```dart
bool getBool(String key, {bool defaultValue = false})
void setBool(String key, bool value)
```

카테고리별 알림 토글 등 동적 키에 사용. 예: `getBool('noti_board_자유', defaultValue: true)`.
