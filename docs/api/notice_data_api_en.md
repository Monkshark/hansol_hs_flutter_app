# NoticeDataApi

> 한국어: [notice_data_api.md](./notice_data_api.md)
>
> `lib/api/notice_data_api.dart` — NEIS school schedule API integration

Instance methods (not a singleton). Queries school schedules from the NEIS school schedule API.
The HTTP client can be replaced through a `@visibleForTesting` static setter, enabling MockClient-based unit tests.

---

## `getNotice`

```dart
Future<String?> getNotice({required DateTime date})
```

**Description**: Returns the school schedule event name for a specific date.

1. Cache check (12-hour TTL):
   ```dart
   final cacheKey = 'notice_$formattedDate';
   // 12시간 이내면 캐시 반환
   ```

2. If offline, returns a guidance message

3. Calls the NEIS `SchoolSchedule` endpoint (`AA_YMD` parameter)

4. Extracts the event name via `_processSchoolSchedule`:
   ```dart
   if (row['EVENT_NM'] == '토요휴업일') return null;
   return row['EVENT_NM'];
   ```
   '토요휴업일' (Saturday holiday) is meaningless, so null is returned.

**Return value**: The event name string, or '학사일정이 없습니다'

---

## `getUpcomingEvent`

```dart
Future<UpcomingEvent?> getUpcomingEvent()
```

**Description**: Returns the nearest future school event.

1. Cache check (6-hour TTL). Recomputes whether D-day is ≥ 0:
   ```dart
   final dDay = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
   if (dDay >= 0) return cached;
   ```

2. Calls the NEIS API for a 90-day range starting tomorrow:
   ```dart
   final tomorrow = now.add(const Duration(days: 1));
   final endDate = now.add(const Duration(days: 90));
   ```

3. Excludes '토요휴업일' and collects only events with D-day > 0.

4. Sorts by D-day → returns the closest event and caches it.

**Return value**: `UpcomingEvent?` — includes `name`, `date`, and `dDay`.

---

## `getEventsInRange`

```dart
Future<List<UpcomingEvent>> getEventsInRange({int days = 30})
```

**Description**: Returns all school events within `days` days from today.

Calls the API every time without caching. Returns a list sorted by D-day.
Used by the "Add D-day from schedule" feature on the D-day screen.

---

## `getMonthEvents`

```dart
Future<Map<DateTime, String>> getMonthEvents(DateTime month)
```

**Description**: Returns a monthly school-event map (for calendar markers).

1. Cache check (12-hour TTL, `month_events_v2_` key):
   ```dart
   final cacheKey = 'month_events_v2_$monthKey';
   ```

2. Calls the API from the first to the last day of the month.

3. Builds a `{ DateTime: "일정명" }` map, excluding '토요휴업일'.

4. Stores to cache (DateTime converted to an ISO string key).

**Return value**: `Map<DateTime, String>` — event name keyed by date.

---

## `_processSchoolSchedule`

```dart
String? _processSchoolSchedule(List<dynamic> schoolScheduleArray)
```

Extracts the first `EVENT_NM` from the `SchoolSchedule` array in the NEIS response. Returns null if it is '토요휴업일'.

---

## `_fetchData`

```dart
Future<Map<String, dynamic>?> _fetchData(String url)
```

Performs an HTTP GET request through `_client`. 10-second timeout; throws `NetworkException` on error.

---

## Testing Support

```dart
static http.Client _client = http.Client();

@visibleForTesting
static set client(http.Client c) => _client = c;
```

Inject `MockClient` via the `client` setter → test parsing / caching / event-sort logic without the network.

---

## UpcomingEvent (data class)

```dart
class UpcomingEvent {
  final String name;
  final DateTime date;
  final int dDay;
}
```

A model representing an upcoming school event.
