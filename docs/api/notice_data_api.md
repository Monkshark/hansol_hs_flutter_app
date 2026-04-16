# NoticeDataApi

> `lib/api/notice_data_api.dart` — NEIS 학사일정 API 연동

인스턴스 메서드 (singleton이 아님). NEIS 학사일정 API에서 학교 일정을 조회함.
HTTP 클라이언트는 `@visibleForTesting` static setter로 교체 가능하여 MockClient 기반 단위 테스트를 지원함

---

## `getNotice`

```dart
Future<String?> getNotice({required DateTime date})
```

**설명**: 특정 날짜의 학사일정 이름을 반환함

1. 캐시 확인 (12시간 TTL):
   ```dart
   final cacheKey = 'notice_$formattedDate';
   // 12시간 이내면 캐시 반환
   ```

2. 오프라인이면 안내 메시지 반환

3. NEIS `SchoolSchedule` 엔드포인트 호출 (`AA_YMD` 파라미터)

4. `_processSchoolSchedule`로 일정명 추출:
   ```dart
   if (row['EVENT_NM'] == '토요휴업일') return null;
   return row['EVENT_NM'];
   ```
   '토요휴업일'은 의미 없으므로 null 반환

**반환값**: 일정명 문자열 또는 '학사일정이 없습니다'

---

## `getUpcomingEvent`

```dart
Future<UpcomingEvent?> getUpcomingEvent()
```

**설명**: 가장 가까운 미래 학사 이벤트를 반환함

1. 캐시 확인 (6시간 TTL). D-day가 0 이상인지 재계산:
   ```dart
   final dDay = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
   if (dDay >= 0) return cached;
   ```

2. 내일부터 90일 범위로 NEIS API 호출:
   ```dart
   final tomorrow = now.add(const Duration(days: 1));
   final endDate = now.add(const Duration(days: 90));
   ```

3. '토요휴업일' 제외, D-day > 0인 이벤트만 수집

4. D-day 기준 정렬 → 가장 가까운 이벤트 반환 + 캐시 저장

**반환값**: `UpcomingEvent?` — `name`, `date`, `dDay` 포함

---

## `getEventsInRange`

```dart
Future<List<UpcomingEvent>> getEventsInRange({int days = 30})
```

**설명**: 오늘부터 `days`일 범위 내 모든 학사 이벤트를 반환함

캐시 없이 매번 API 호출. D-day 기준 정렬된 리스트 반환
D-day 화면에서 "일정에서 D-day 추가" 기능에 사용

---

## `getMonthEvents`

```dart
Future<Map<DateTime, String>> getMonthEvents(DateTime month)
```

**설명**: 월별 학사일정 맵을 반환함 (캘린더 마커용)

1. 캐시 확인 (12시간 TTL, `month_events_v2_` 키):
   ```dart
   final cacheKey = 'month_events_v2_$monthKey';
   ```

2. 월의 첫날~마지막날 범위로 API 호출

3. `{ DateTime: "일정명" }` 맵 구성, '토요휴업일' 제외

4. 캐시 저장 (DateTime을 ISO string 키로 변환)

**반환값**: `Map<DateTime, String>` — 날짜별 일정명

---

## `_processSchoolSchedule`

```dart
String? _processSchoolSchedule(List<dynamic> schoolScheduleArray)
```

NEIS 응답의 `SchoolSchedule` 배열에서 첫 번째 `EVENT_NM`을 추출. '토요휴업일'이면 null

---

## `_fetchData`

```dart
Future<Map<String, dynamic>?> _fetchData(String url)
```

`_client`를 통해 HTTP GET 요청. 10초 타임아웃, 에러 시 `NetworkException` throw

---

## 테스트 지원

```dart
static http.Client _client = http.Client();

@visibleForTesting
static set client(http.Client c) => _client = c;
```

`client` setter로 `MockClient` 주입 → 네트워크 없이 파싱·캐시·이벤트 정렬 로직 테스트

---

## UpcomingEvent (데이터 클래스)

```dart
class UpcomingEvent {
  final String name;
  final DateTime date;
  final int dDay;
}
```

다가오는 학사 이벤트를 나타내는 모델
