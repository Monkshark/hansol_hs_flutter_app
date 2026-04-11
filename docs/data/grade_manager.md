# GradeManager

> `lib/data/grade_manager.dart` — 성적 CRUD, 목표 관리, 등급 변환

`SubjectScore`, `Exam` 모델과 `GradeManager` 클래스를 포함. 모든 메서드가 `static`. 데이터는 [`SecureStorageService`](secure_storage_service.md)에 JSON으로 암호화 저장 (서버 저장 안 함)

---

## SubjectScore (데이터 모델)

```dart
class SubjectScore {
  final String subject;
  final int? rawScore;        // 원점수
  final int? rank;            // 등급 (1~9)
  final double? percentile;   // 백분위
  final double? standardScore; // 표준점수
  final double? average;       // 평균
  final String? achievement;   // 성취도 A~E
}
```

내신(rawScore/average/rank/achievement)과 모의고사(percentile/standardScore/rank)를 하나의 구조체로 통합

### 상수

| 상수 | 값 |
|------|----|
| `rankCutoffs` | `{1: '상위 10%', 2: '상위 34%', ...}` — 내신 5등급 비율 |
| `achievements` | `['A', 'B', 'C', 'D', 'E']` |

---

## Exam (데이터 모델)

```dart
class Exam {
  final String id;
  final String type;        // 'midterm' | 'final' | 'mock' | 'private_mock'
  final int year;
  final int semester;       // 1 or 2
  final int grade;          // 1, 2, 3
  final String? mockLabel;  // 모의: '3월', '6월' / 사설: 직접 입력
  final List<SubjectScore> scores;
  final DateTime createdAt;
}
```

`displayName` 프로퍼티: type별 한국어 표시명 생성
```dart
'midterm' → '$year ${semester}학기 중간고사'
'mock'    → '$year $mockLabel 모의고사'
```

---

## `percentileToRank`

```dart
static int percentileToRank(double percentile)
```

**설명**: 수능 백분위를 등급으로 변환함 (9등급제)

```dart
if (percentile >= 96) return 1;
if (percentile >= 89) return 2;
if (percentile >= 77) return 3;
// ... 4~8등급
return 9;
```

---

## `loadExams`

```dart
static Future<List<Exam>> loadExams()
```

**설명**: 저장된 시험 목록을 로드함

1. SharedPreferences → SecureStorage 일회성 마이그레이션:
   ```dart
   await SecureStorageService.migrateFromPlain(
     key: SecureStorageService.keyGradeExams,
     oldValue: prefs.getString(_examsKey),
     onMigrated: () async => prefs.remove(_examsKey),
   );
   ```

2. SecureStorage에서 JSON 읽기 후 `Exam.fromJson`으로 디코딩:
   ```dart
   final json = await SecureStorageService.read(SecureStorageService.keyGradeExams);
   final list = jsonDecode(json) as List<dynamic>;
   return list.map((e) => Exam.fromJson(e)).toList()
     ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
   ```

**마이그레이션**: 기존 SharedPreferences(평문)에서 SecureStorage(암호화)로 자동 이전. 한 번 옮기면 이전 데이터 삭제

---

## `saveExams`

```dart
static Future<void> saveExams(List<Exam> exams)
```

시험 목록 전체를 SecureStorage에 JSON으로 저장

---

## `addExam` / `updateExam` / `deleteExam`

```dart
static Future<void> addExam(Exam exam)
static Future<void> updateExam(Exam exam)
static Future<void> deleteExam(String id)
```

각각 `loadExams()` → 수정 → `saveExams()` 패턴. `updateExam`은 id 매칭, `deleteExam`은 `removeWhere`

---

## `loadGoals`

```dart
static Future<Map<String, double>> loadGoals()
```

**설명**: 수시 목표 등급(과목명 → 등급)을 로드함

`loadExams`와 동일한 마이그레이션 + SecureStorage 패턴. 키: `SecureStorageService.keyGradeGoals`

---

## `saveGoals`

```dart
static Future<void> saveGoals(Map<String, double> goals)
```

수시 목표를 SecureStorage에 JSON 저장

---

## `loadJeongsiGoals` / `saveJeongsiGoals`

```dart
static Future<Map<String, double>> loadJeongsiGoals()
static Future<void> saveJeongsiGoals(Map<String, double> goals)
```

정시 목표(백분위 기준). 키: `SecureStorageService.keyGradeJeongsiGoals`. 로직은 `loadGoals`/`saveGoals`와 동일

---

## 상수 데이터

### `mockSubjects`

2022 개정 교육과정 수능 과목 맵:
```dart
{
  '공통': ['국어', '수학', '영어', '한국사', '통합사회', '통합과학'],
  '직업탐구': ['성공적인 직업생활'],
  '제2외국어/한문 (택 1)': ['독일어', '프랑스어', ... '한문'],
}
```

### `subjectColors`

과목별 고정 색상 (차트용):
```dart
{'국어': 0xFFE53935, '수학': 0xFF1E88E5, '영어': 0xFF43A047, ...}
```

### `getSubjectColor`

```dart
static int getSubjectColor(String subject)
```

`subjectColors`에 없는 과목은 `subject.hashCode | 0xFF000000`로 결정론적 색상 생성
