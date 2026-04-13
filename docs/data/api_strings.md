# ApiStrings

> `lib/data/api_strings.dart` — API 계층 센티널 문자열 상수

API 응답에서 데이터 유무를 판별하는 한국어 문자열을 상수로 관리. UI 표시용이 아닌 `==` 비교에 사용되므로 l10n 대상이 아님

---

## 용도

API에서 "데이터 없음" 또는 "인터넷 없음" 상태를 반환할 때 하드코딩된 한국어 문자열 대신 상수를 사용하여 오타·불일치를 방지

```dart
// Before
if (result == '급식 정보가 없습니다.') { ... }

// After
if (result == ApiStrings.mealNoData) { ... }
```

---

## 상수 목록

### 급식 (Meal)

| 상수 | 값 | 사용 위치 |
|------|------|----------|
| `mealNoData` | `'급식 정보가 없습니다.'` | [meal_data_api](../api/meal_data_api.md), meal_card, meal_screen |
| `mealNoDataLegacy` | `'급식 정보가 없습니다'` | meal_screen (마침표 없는 구버전 호환) |
| `mealNoInternet` | `'식단 정보를 확인하려면 인터넷에 연결하세요'` | [meal_data_api](../api/meal_data_api.md) |

### 시간표 (Timetable)

| 상수 | 값 | 사용 위치 |
|------|------|----------|
| `timetableNoInternet` | `'시간표를 확인하려면 인터넷에 연결하세요'` | [timetable_data_api](../api/timetable_data_api.md) |
| `timetableNoData` | `'정보 없음'` | [timetable_data_api](../api/timetable_data_api.md) |

### 학사일정 (Notice)

| 상수 | 값 | 사용 위치 |
|------|------|----------|
| `noticeNoInternet` | `'학사일정을 확인하려면 인터넷에 연결하세요'` | [notice_data_api](../api/notice_data_api.md) |
| `noticeNoData` | `'학사일정이 없습니다'` | [notice_data_api](../api/notice_data_api.md), notice_screen |

---

## 설계 참고

- **l10n과 별개**: 이 문자열은 API 반환값과의 `==` 비교용이므로 번역하면 안 됨. UI에 노출되는 문자열은 `AppLocalizations`에서 별도 관리
- `mealNoDataLegacy`: 마침표 유무 차이로 인한 하위 호환. 신규 코드는 `mealNoData` 사용
