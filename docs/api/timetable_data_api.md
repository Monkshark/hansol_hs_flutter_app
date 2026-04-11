# TimetableDataApi

> `lib/api/timetable_data_api.dart` — NEIS 시간표 API 연동

모든 메서드가 `static`. 시간표 데이터 조회, 과목 조합 추출, 캐싱을 담당함

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

**설명**: 학년/반별 시간표를 날짜 범위로 조회함

**반환 구조**: `{ "20260410": { "3": ["국어","수학","영어",...] } }` — 날짜 → 반 → 교시별 과목 리스트

1. 캐시 확인 (12시간 TTL):
   ```dart
   final cacheKey = '$formattedStartDate-$formattedEndDate-$grade${classNum != null ? '-$classNum' : ''}';
   ```

2. 오프라인이면 에러 맵 반환:
   ```dart
   return {"error": {"error": ["시간표를 확인하려면 인터넷에 연결하세요"]}};
   ```

3. NEIS `hisTimetable` 엔드포인트 호출 (`pSize=1000`):
   ```dart
   '&GRADE=$grade'
   '${classNum != null ? '&CLASS_NM=$classNum' : ''}'
   ```

4. `_processTimetable`로 응답 파싱 후 캐시에 저장

---

## `_processTimetable`

```dart
static Map<String, Map<String, List<String>>> _processTimetable(
    List<dynamic> timetableArray)
```

**설명**: NEIS API 응답을 `{ 날짜 → 반 → 과목리스트 }` 구조로 변환함

핵심 로직 — **PERIO 기반 교시 배치**:
```dart
final perio = int.tryParse(item['PERIO']?.toString() ?? '');
while (classList.length < perio) {
  classList.add('');  // 빈 교시 채우기
}
classList[perio - 1] = content;  // 1-based → 0-based
```

반 번호가 없는 경우 `'special'`로 처리 (특별실 과목)

---

## `_getWeekTimetableWithFallback`

```dart
static Future<Map<String, Map<String, List<String>>>> _getWeekTimetableWithFallback(
    String grade)
```

**설명**: 이번 주 → 다음 주 → 지난 주 순으로 시간표를 시도함

방학 등 데이터가 없는 주를 대비한 폴백:
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

**설명**: 학년별 과목명 리스트를 추출함

`_getWeekTimetableWithFallback`로 시간표를 가져온 뒤, 모든 과목명을 `Set`으로 수집
`[보강]`, `토요휴업일` 제외. 1주일 캐시

---

## `getAllSubjectCombinations`

```dart
static Future<List<Subject>> getAllSubjectCombinations({
  required int grade,
  int maxRetries = 3,
})
```

**설명**: 학년의 모든 반에서 가르치는 과목 + 반 번호 조합을 추출함

시간표 선택 화면에서 "어떤 반에서 어떤 과목을 가르치는지" 파악에 사용

1. 로컬 캐시 확인 (1주일 TTL):
   ```dart
   final cachedSubjects = await _loadCachedSubjects(grade);
   if (cachedSubjects != null && cachedSubjects.isNotEmpty) return cachedSubjects;
   ```

2. 최대 3회 재시도로 `_getWeekTimetableWithFallback` 호출:
   ```dart
   for (int attempt = 1; attempt <= maxRetries; attempt++) { ... }
   ```

3. `Subject(subjectName, subjectClass)` 쌍을 Set으로 수집:
   ```dart
   subjectSet.add(Subject(
     subjectName: subjectName,
     subjectClass: classInt,  // -1이면 특별실
   ));
   ```

4. 이름순 정렬 후 캐시 저장

**재시도**: 실패 시 `2 * attempt`초 대기 후 재시도

---

## `getCustomTimeTable`

```dart
static Future<List<List<String?>>> getCustomTimeTable({
  required List<Subject> userSubjects,
  required String grade,
})
```

**설명**: 사용자가 선택한 과목으로 커스텀 시간표를 생성함

**반환**: `List<List<String?>>` — 인덱스 1~5가 월~금, 각 리스트의 인덱스 1~7이 1~7교시

1. 전체 학년 시간표를 조회 (반 지정 없이):
   ```dart
   final timetable = await getTimeTable(..., classNum: null);
   ```

2. 사용자 선택 과목을 반 번호로 그룹화:
   ```dart
   final classToSubjects = <int, List<Subject>>{};
   ```

3. 각 반의 시간표에서 선택 과목이 매칭되는 교시를 추출:
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

NEIS `classInfo` API로 학년의 반 수를 조회함. 1주일 캐시

---

## `getSubjectsFromAdminFirestore`

```dart
static Future<List<Subject>> getSubjectsFromAdminFirestore(int grade)
```

Firestore `grade/{grade}/subject/` 컬렉션에서 관리자가 등록한 과목 목록을 조회함
`category`와 `isOriginal` 필드 포함

---

## 내부 유틸리티

| 함수 | 설명 |
|------|------|
| `_fetchData(url)` | HTTP GET 요청, 에러 시 null |
| `_hasData(timetable)` | 에러가 아니고 과목 데이터가 있는지 |
| `_loadCachedSubjects(grade)` | 과목 조합 캐시 로드 (1주일 TTL) |
| `_saveSubjectsToCache(grade, subjects)` | 과목 조합 캐시 저장 |
