# MealDataApi

> 한국어: [meal_data_api.md](./meal_data_api.md)
>
> `lib/api/meal_data_api.dart` — NEIS meal API integration

All methods are `static`. Queries meal data from the NEIS education information API and caches it in SharedPreferences.
The HTTP client can be replaced through a `@visibleForTesting` setter, enabling MockClient-based unit tests.

---

## Constants

| Constant | Value | Description |
|------|----|------|
| `BREAKFAST` | 1 | Breakfast code |
| `LUNCH` | 2 | Lunch code |
| `DINNER` | 3 | Dinner code |

---

## `getMeal`

```dart
static Future<Meal?> getMeal({
  required DateTime date,
  required int mealType,
  required String type,
})
```

**Description**: Returns the meal data for a specific date and meal type.

**Flow**:

1. Build the cache key:
   ```dart
   final cacheKey = _cacheKey(date, mealType);
   // → "meal_20260410_2" 형태
   ```

2. Look up SharedPreferences. Return immediately if valid:
   ```dart
   final cached = _getFromCache(prefs, cacheKey);
   if (cached != null && cached.meal != null && cached.meal != '급식 정보가 없습니다.') {
     return cached;
   }
   ```

3. If offline, return cached data or a guidance message:
   ```dart
   if (await NetworkStatus.isUnconnected()) {
     if (cached != null) return cached;
     return Meal(meal: "식단 정보를 확인하려면 인터넷에 연결하세요", ...);
   }
   ```

4. Attempt a monthly prefetch to cache the entire month's meals in one go:
   ```dart
   await _prefetchMonth(date);
   ```

5. Re-check the cache after prefetching. Return it if present; otherwise, fetch individually:
   ```dart
   final afterPrefetch = _getFromCache(prefs, cacheKey);
   if (afterPrefetch != null) return afterPrefetch;
   return _fetchSingleMeal(date, mealType, prefs, cacheKey);
   ```

**Return value**: `Meal?` — meal data. When absent, `meal: '급식 정보가 없습니다.'`

---

## `_fetchSingleMeal`

```dart
static Future<Meal> _fetchSingleMeal(
  DateTime date, int mealType, SharedPreferences prefs, String cacheKey)
```

**Description**: Directly requests a single day's meal via the NEIS API.

1. Build the NEIS API URL:
   ```dart
   final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?...'
       '&MMEAL_SC_CODE=$mealType'
       '&MLSV_YMD=$formattedDate';
   ```

2. HTTP GET request via `_fetchData`:
   ```dart
   final data = await _fetchData(requestURL);
   ```

3. Parse `mealServiceDietInfo > row` from the response:
   ```dart
   meal: (row['DDISH_NM'] as String).replaceAll('<br/>', '\n'),
   kcal: row['CAL_INFO'] as String,
   ntrInfo: (row['NTR_INFO'] as String?)?.replaceAll('<br/>', '\n') ?? '',
   ```
   `<br/>` tags are replaced with newlines.

4. Save the result to cache and return. If no data is found, returns '급식 정보가 없습니다.'

---

## `_prefetchMonth`

```dart
static Future<void> _prefetchMonth(DateTime date)
```

**Description**: Prefetches the entire month's meals in a single API call.

1. If the same month is already being prefetched, await that Future:
   ```dart
   if (_prefetchingMonths.containsKey(monthKey)) {
     await _prefetchingMonths[monthKey];
     return;
   }
   ```
   Uses a `Completer` to prevent duplicate requests.

2. Call the API with the first to last day of the month:
   ```dart
   '&MLSV_FROM_YMD=$fromDate'
   '&MLSV_TO_YMD=$toDate'
   '&pSize=100'
   ```

3. Save every row in the response under its individual cache key:
   ```dart
   final key = _cacheKey(mealDate, mealCode);
   _saveToCache(prefs, key, meal);
   ```

4. Remove from the `_prefetchingMonths` map in `finally`.

---

## `prefetchWeek`

```dart
static Future<void> prefetchWeek(DateTime baseDate)
```

**Description**: Prefetches the meals for the current week when the weekly view is opened.

- One `_prefetchMonth` call if Monday–Friday share the same month
- Two parallel prefetches if the week crosses months:
  ```dart
  await Future.wait([_prefetchMonth(monday), _prefetchMonth(friday)]);
  ```

---

## `_getFromCache`

```dart
static Meal? _getFromCache(SharedPreferences prefs, String key)
```

**Description**: Reads meal data from the cache, returning null if expired.

**Caching strategy (tiered TTL)**:
- Normal meal data → **24 hours** cached
- '급식 정보가 없습니다.' → cached for **5 minutes** (since data may be registered shortly)

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

Saves [Meal](../data/meal.md) JSON + timestamp into SharedPreferences.

---

## `clearCacheForDate`

```dart
static Future<void> clearCacheForDate(DateTime date)
```

Clears breakfast/lunch/dinner caches for a specific date.

---

## `_fetchData`

```dart
static Future<Map<String, dynamic>?> _fetchData(String url)
```

**Description**: Performs an HTTP GET request through `_client`.

- **Timeout**: 10 seconds
- NEIS `INFO-200` (no data) responses are returned normally (empty data)
- Throws `NetworkException` on error/timeout (caller handles cache fallback)

---

## Testing Support

```dart
static http.Client _client = http.Client();

@visibleForTesting
static set client(http.Client c) => _client = c;

@visibleForTesting
static Future<void> resetCache() async { ... }
```

- Inject `MockClient` via the `client` setter → test parsing/cache/SWR logic without the network
- `resetCache()` resets `_prefetchingMonths` + SharedPreferences

---

## `isAllMealEmpty`

```dart
static Future<bool> isAllMealEmpty(DateTime date)
```

**Description**: Checks whether any meal exists for a given date.
Returns `true` on a NEIS `INFO-200` response (no meals).
Used by the home widget to decide whether to display "No meals".
