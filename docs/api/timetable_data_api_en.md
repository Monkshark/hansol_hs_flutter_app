# TimetableDataApi

> 한국어: [timetable_data_api.md](./timetable_data_api.md)
>
> `lib/api/timetable_data_api.dart` — NEIS timetable API integration

All methods are `static`. Responsible for querying timetable data, extracting subject combinations, and caching.
The HTTP client can be replaced through a `@visibleForTesting` setter, enabling MockClient-based unit tests.

---

## `getTimeTable`

```dart
static Future<Map<String, Map<String, List<String>>>> getTimeTable({
  required DateTime startDate,
  required DateTime endDate,
  required String grade,
  String? classNum,
})
```

**Description**: Queries a timetable for a grade/class over a date range.

**Return structure**: `{ "20260410": { "3": ["국어","수학","영어",...] } }` — date → class → per-period subject list.

1. Cache check (12-hour TTL):
   ```dart
   final cacheKey = '$formattedStartDate-$formattedEndDate-$grade${classNum != null ? '-$classNum' : ''}';
   ```

2. When offline, returns an error map:
   ```dart
   return {"error": {"error": ["시간표를 확인하려면 인터넷에 연결하세요"]}};
   ```

3. Calls the NEIS `hisTimetable` endpoint (`pSize=1000`):
   ```dart
   '&GRADE=$grade'
   '${classNum != null ? '&CLASS_NM=$classNum' : ''}'
   ```

4. Parses the response via `_processTimetable` and stores it in the cache.

---

## `_processTimetable`

```dart
static Map<String, Map<String, List<String>>> _processTimetable(
    List<dynamic> timetableArray)
```

**Description**: Converts the NEIS API response into a `{ date → class → subject list }` structure.

Core logic — **period placement based on PERIO**:
```dart
final perio = int.tryParse(item['PERIO']?.toString() ?? '');
while (classList.length < perio) {
  classList.add('');  // 빈 교시 채우기
}
classList[perio - 1] = content;  // 1-based → 0-based
```

Entries without a class number are treated as `'special'` (special-room subjects).

---

## `_getWeekTimetableWithFallback`

```dart
static Future<Map<String, Map<String, List<String>>>> _getWeekTimetableWithFallback(
    String grade)
```

**Description**: Tries this week → next week → last week in order.

A fallback for weeks with no data (e.g., vacations):
```dart
var timetable = await getTimeTable(startDate: thisMonday, ...);
if (_hasData(timetable)) return timetable;

// 이번 주 없으면 다음 주 시도
final nextMonday = thisMonday.add(const Duration(days: 7));
timetable = await getTimeTable(startDate: nextMonday, ...);
if (_hasData(timetable)) return timetable;

// 다음 주도 없으면 지난 주 시도
final prevMonday = thisMonday.subtract(const Duration(days: 7));
return await getTimeTable(startDate: prevMonday, ...);
```

---

## `getSubjects`

```dart
static Future<List<String>?> getSubjects({required int grade})
```

**Description**: Extracts the list of subject names for a given grade.

Fetches the timetable via `_getWeekTimetableWithFallback`, then collects every subject name into a `Set`.
Excludes `[보강]` and `토요휴업일`. Cached for 1 week.

---

## `getAllSubjectCombinations`

```dart
static Future<List<Subject>> getAllSubjectCombinations({
  required int grade,
  int maxRetries = 3,
})
```

**Description**: Extracts combinations of subjects + class numbers taught across every class of a grade.

Used on the timetable selection screen to determine "which subjects are taught in which classes".

1. Local cache check (1-week TTL):
   ```dart
   final cachedSubjects = await _loadCachedSubjects(grade);
   if (cachedSubjects != null && cachedSubjects.isNotEmpty) return cachedSubjects;
   ```

2. Calls `_getWeekTimetableWithFallback` with up to 3 retries:
   ```dart
   for (int attempt = 1; attempt <= maxRetries; attempt++) { ... }
   ```

3. Collects `Subject(subjectName, subjectClass)` pairs into a Set:
   ```dart
   subjectSet.add(Subject(
     subjectName: subjectName,
     subjectClass: classInt,  // -1이면 특별실
   ));
   ```

4. Sorts by name and saves to cache.

**Retry**: On failure, waits `2 * attempt` seconds before retrying.

---

## `getCustomTimeTable`

```dart
static Future<List<List<String?>>> getCustomTimeTable({
  required List<Subject> userSubjects,
  required String grade,
})
```

**Description**: Builds a custom timetable from the user's selected subjects.

**Return**: `List<List<String?>>` — indices 1–5 are Monday–Friday, and within each list indices 1–7 are periods 1–7.

1. Queries the full-grade timetable (without specifying a class):
   ```dart
   final timetable = await getTimeTable(..., classNum: null);
   ```

2. Groups the user's selected subjects by class number:
   ```dart
   final classToSubjects = <int, List<Subject>>{};
   ```

3. Extracts the periods from each class's timetable where a selected subject matches:
   ```dart
   if (subjectsList[i] == subject.subjectName) {
     customTimeTable[weekday][i + 1] = subject.subjectName;
   }
   ```

---

## `getClassCount`

```dart
static Future<int> getClassCount(int grade)
```

Queries the number of classes in a grade via the NEIS `classInfo` API. Cached for 1 week.

---

## `getSubjectsFromAdminFirestore`

```dart
static Future<List<Subject>> getSubjectsFromAdminFirestore(int grade)
```

Queries the admin-registered subject list from the Firestore `grade/{grade}/subject/` collection.
Includes the `category` and `isOriginal` fields.

---

## Internal Utilities

| Function | Description |
|------|------|
| `_fetchData(url)` | Performs an HTTP GET through `_client`; throws `NetworkException` on error |
| `_hasData(timetable)` | Whether it is not an error and contains subject data |
| `_loadCachedSubjects(grade)` | Loads the subject-combination cache (1-week TTL) |
| `_saveSubjectsToCache(grade, subjects)` | Saves the subject-combination cache |

---

## Testing Support

```dart
static http.Client _client = http.Client();

@visibleForTesting
static set client(http.Client c) => _client = c;
```

Inject `MockClient` via the `client` setter → test parsing / caching / SWR / subject-extraction logic without the network.
