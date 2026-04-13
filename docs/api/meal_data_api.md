# MealDataApi

> `lib/api/meal_data_api.dart` — NEIS 급식 API 연동

모든 메서드가 `static`. NEIS 교육정보 API에서 급식 데이터를 조회하고, SharedPreferences에 캐싱함.
HTTP 클라이언트는 `@visibleForTesting` setter로 교체 가능하여 MockClient 기반 단위 테스트를 지원함

---

## 상수

| 상수 | 값 | 설명 |
|------|----|------|
| `BREAKFAST` | 1 | 조식 코드 |
| `LUNCH` | 2 | 중식 코드 |
| `DINNER` | 3 | 석식 코드 |

---

## `getMeal`

```dart
static Future<Meal?> getMeal({
  required DateTime date,
  required int mealType,
  required String type,
})
```

**설명**: 특정 날짜·식사 유형의 급식 데이터를 반환함

**흐름**:

1. 캐시 키를 생성함:
   ```dart
   final cacheKey = _cacheKey(date, mealType);
   // → "meal_20260410_2" 형태
   ```

2. SharedPreferences에서 캐시를 조회. 유효한 데이터면 즉시 반환:
   ```dart
   final cached = _getFromCache(prefs, cacheKey);
   if (cached != null && cached.meal != null && cached.meal != '급식 정보가 없습니다.') {
     return cached;
   }
   ```

3. 오프라인이면 캐시 데이터 또는 안내 메시지 반환:
   ```dart
   if (await NetworkStatus.isUnconnected()) {
     if (cached != null) return cached;
     return Meal(meal: "식단 정보를 확인하려면 인터넷에 연결하세요", ...);
   }
   ```

4. 월간 프리페치를 시도해 해당 월 전체 급식을 한 번에 캐싱:
   ```dart
   await _prefetchMonth(date);
   ```

5. 프리페치 후 캐시 재확인. 있으면 반환, 없으면 개별 요청:
   ```dart
   final afterPrefetch = _getFromCache(prefs, cacheKey);
   if (afterPrefetch != null) return afterPrefetch;
   return _fetchSingleMeal(date, mealType, prefs, cacheKey);
   ```

**반환값**: `Meal?` — 급식 데이터. 없으면 `meal: '급식 정보가 없습니다.'`

---

## `_fetchSingleMeal`

```dart
static Future<Meal> _fetchSingleMeal(
  DateTime date, int mealType, SharedPreferences prefs, String cacheKey)
```

**설명**: 단일 날짜·식사의 급식을 NEIS API로 직접 요청함

1. NEIS API URL을 구성:
   ```dart
   final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?...'
       '&MMEAL_SC_CODE=$mealType'
       '&MLSV_YMD=$formattedDate';
   ```

2. `_fetchData`로 HTTP GET 요청:
   ```dart
   final data = await _fetchData(requestURL);
   ```

3. 응답의 `mealServiceDietInfo > row`를 파싱:
   ```dart
   meal: (row['DDISH_NM'] as String).replaceAll('<br/>', '\n'),
   kcal: row['CAL_INFO'] as String,
   ntrInfo: (row['NTR_INFO'] as String?)?.replaceAll('<br/>', '\n') ?? '',
   ```
   `<br/>` 태그를 줄바꿈으로 치환

4. 결과를 캐시에 저장 후 반환. 데이터 없으면 '급식 정보가 없습니다.' 반환

---

## `_prefetchMonth`

```dart
static Future<void> _prefetchMonth(DateTime date)
```

**설명**: 해당 월의 전체 급식을 한 번의 API 호출로 프리페치함

1. 같은 월이 이미 프리페치 중이면 그 Future를 대기:
   ```dart
   if (_prefetchingMonths.containsKey(monthKey)) {
     await _prefetchingMonths[monthKey];
     return;
   }
   ```
   `Completer`로 중복 요청 방지

2. 월의 첫날~마지막날 범위로 API 호출:
   ```dart
   '&MLSV_FROM_YMD=$fromDate'
   '&MLSV_TO_YMD=$toDate'
   '&pSize=100'
   ```

3. 응답의 모든 row를 개별 캐시 키로 저장:
   ```dart
   final key = _cacheKey(mealDate, mealCode);
   _saveToCache(prefs, key, meal);
   ```

4. `finally`에서 `_prefetchingMonths` 맵에서 제거

---

## `prefetchWeek`

```dart
static Future<void> prefetchWeek(DateTime baseDate)
```

**설명**: 주간 뷰 진입 시 해당 주의 급식을 프리페치함

- 월~금이 같은 달이면 `_prefetchMonth` 1회
- 달이 걸치면 2개월 병렬 프리페치:
  ```dart
  await Future.wait([_prefetchMonth(monday), _prefetchMonth(friday)]);
  ```

---

## `_getFromCache`

```dart
static Meal? _getFromCache(SharedPreferences prefs, String key)
```

**설명**: 캐시에서 급식 데이터를 읽되, 만료된 데이터는 null 반환함

**캐시 전략 (차등 TTL)**:
- 정상 급식 데이터 → **24시간** 캐시
- '급식 정보가 없습니다.' → **5분** 캐시 (곧 등록될 수 있으므로)

```dart
if (meal.meal == '급식 정보가 없습니다.') {
  if (age > 5 * 60 * 1000) return null;   // 5분 후 만료
} else {
  if (age > 24 * 60 * 60 * 1000) return null;  // 24시간 후 만료
}
```

---

## `_saveToCache`

```dart
static void _saveToCache(SharedPreferences prefs, String key, Meal meal)
```

[Meal](../data/meal.md) JSON + 타임스탬프를 SharedPreferences에 저장

---

## `clearCacheForDate`

```dart
static Future<void> clearCacheForDate(DateTime date)
```

특정 날짜의 조식/중식/석식 캐시를 모두 삭제함

---

## `_fetchData`

```dart
static Future<Map<String, dynamic>?> _fetchData(String url)
```

**설명**: `_client`를 통해 HTTP GET 요청을 수행함

- **타임아웃**: 10초
- NEIS `INFO-200` (데이터 없음) 응답은 `null` 반환
- 에러/타임아웃도 `null` 반환 (silent fail)

---

## 테스트 지원

```dart
static http.Client _client = http.Client();

@visibleForTesting
static set client(http.Client c) => _client = c;

@visibleForTesting
static Future<void> resetCache() async { ... }
```

- `client` setter로 `MockClient` 주입 → 네트워크 없이 파싱·캐시·SWR 로직 테스트
- `resetCache()`로 `_prefetchingMonths` + SharedPreferences 초기화

---

## `isAllMealEmpty`

```dart
static Future<bool> isAllMealEmpty(DateTime date)
```

**설명**: 특정 날짜에 급식이 하나도 없는지 확인함
NEIS `INFO-200` 응답이면 `true` (급식 없음)
홈 위젯에서 "급식 없음" 표시 여부 판단에 사용
