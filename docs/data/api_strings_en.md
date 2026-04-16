# ApiStrings

> 한국어: [api_strings.md](./api_strings.md)

> `lib/data/api_strings.dart` — Sentinel string constants for the API layer

Manages Korean strings used to determine data presence in API responses as constants. Not subject to l10n since they are used for `==` comparison, not UI display.

---

## Purpose

Prevent typos and mismatches by using constants instead of hardcoded Korean strings when an API returns a "no data" or "no internet" state.

```dart
// Before
if (result == '급식 정보가 없습니다.') { ... }

// After
if (result == ApiStrings.mealNoData) { ... }
```

---

## Constant list

### Meal

| Constant | Value | Usage |
|------|------|----------|
| `mealNoData` | `'급식 정보가 없습니다.'` | [meal_data_api](../api/meal_data_api.md), meal_card, meal_screen |
| `mealNoDataLegacy` | `'급식 정보가 없습니다'` | meal_screen (legacy compatibility without trailing period) |
| `mealNoInternet` | `'식단 정보를 확인하려면 인터넷에 연결하세요'` | [meal_data_api](../api/meal_data_api.md) |

### Timetable

| Constant | Value | Usage |
|------|------|----------|
| `timetableNoInternet` | `'시간표를 확인하려면 인터넷에 연결하세요'` | [timetable_data_api](../api/timetable_data_api.md) |
| `timetableNoData` | `'정보 없음'` | [timetable_data_api](../api/timetable_data_api.md) |

### Notice (academic calendar)

| Constant | Value | Usage |
|------|------|----------|
| `noticeNoInternet` | `'학사일정을 확인하려면 인터넷에 연결하세요'` | [notice_data_api](../api/notice_data_api.md) |
| `noticeNoData` | `'학사일정이 없습니다'` | [notice_data_api](../api/notice_data_api.md), notice_screen |

---

## Design notes

- **Separate from l10n**: These strings are used for `==` comparison against API return values and must not be translated. Strings exposed in the UI are managed separately in `AppLocalizations`.
- `mealNoDataLegacy`: Backward compatibility due to the difference in trailing period. New code should use `mealNoData`.
