# GradeManager

> 한국어: [grade_manager.md](./grade_manager.md)

> `lib/data/grade_manager.dart` — Grade CRUD, goal management, rank conversion

Contains the `SubjectScore`, `Exam` models and the `GradeManager` class. All methods are `static`. Data is encrypted and stored as JSON in [`SecureStorageService`](secure_storage_service.md) (not stored on the server).

---

## SubjectScore (data model)

```dart
class SubjectScore {
  final String subject;
  final int? rawScore;        // raw score
  final int? rank;            // rank (1~9)
  final double? percentile;   // percentile
  final double? standardScore; // standard score
  final double? average;       // average
  final String? achievement;   // achievement level A~E
}
```

Unifies internal school grades (rawScore/average/rank/achievement) and mock exams (percentile/standardScore/rank) into a single structure.

### Constants

| Constant | Value |
|------|----|
| `rankCutoffs` | `{1: '상위 10%', 2: '상위 34%', ...}` — 5-rank ratio for internal grades |
| `achievements` | `['A', 'B', 'C', 'D', 'E']` |

---

## Exam (data model)

```dart
class Exam {
  final String id;
  final String type;        // 'midterm' | 'final' | 'mock' | 'private_mock'
  final int year;
  final int semester;       // 1 or 2
  final int grade;          // 1, 2, 3
  final String? mockLabel;  // mock: '3월', '6월' / private mock: custom input
  final List<SubjectScore> scores;
  final DateTime createdAt;
}
```

`displayName` property: generates a Korean display name per type.
```dart
'midterm' → '$year ${semester}학기 중간고사'
'mock'    → '$year $mockLabel 모의고사'
```

---

## `percentileToRank`

```dart
static int percentileToRank(double percentile)
```

**Description**: Converts a CSAT percentile into a rank (9-rank scale).

```dart
if (percentile >= 96) return 1;
if (percentile >= 89) return 2;
if (percentile >= 77) return 3;
// ... ranks 4~8
return 9;
```

---

## `loadExams`

```dart
static Future<List<Exam>> loadExams()
```

**Description**: Loads the saved exam list.

1. One-time migration from SharedPreferences to SecureStorage:
   ```dart
   await SecureStorageService.migrateFromPlain(
     key: SecureStorageService.keyGradeExams,
     oldValue: prefs.getString(_examsKey),
     onMigrated: () async => prefs.remove(_examsKey),
   );
   ```

2. Read JSON from SecureStorage and decode via `Exam.fromJson`:
   ```dart
   final json = await SecureStorageService.read(SecureStorageService.keyGradeExams);
   final list = jsonDecode(json) as List<dynamic>;
   return list.map((e) => Exam.fromJson(e)).toList()
     ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
   ```

**Migration**: Automatically moves existing SharedPreferences (plaintext) data to SecureStorage (encrypted). Deletes the original data once moved.

---

## `saveExams`

```dart
static Future<void> saveExams(List<Exam> exams)
```

Saves the entire exam list as JSON to SecureStorage.

---

## `addExam` / `updateExam` / `deleteExam`

```dart
static Future<void> addExam(Exam exam)
static Future<void> updateExam(Exam exam)
static Future<void> deleteExam(String id)
```

Each follows the `loadExams()` → modify → `saveExams()` pattern. `updateExam` matches by id, `deleteExam` uses `removeWhere`.

---

## `loadGoals`

```dart
static Future<Map<String, double>> loadGoals()
```

**Description**: Loads early-admission target ranks (subject name → rank).

Same migration + SecureStorage pattern as `loadExams`. Key: `SecureStorageService.keyGradeGoals`.

---

## `saveGoals`

```dart
static Future<void> saveGoals(Map<String, double> goals)
```

Saves early-admission targets as JSON to SecureStorage.

---

## `loadJeongsiGoals` / `saveJeongsiGoals`

```dart
static Future<Map<String, double>> loadJeongsiGoals()
static Future<void> saveJeongsiGoals(Map<String, double> goals)
```

Regular-admission targets (percentile-based). Key: `SecureStorageService.keyGradeJeongsiGoals`. Logic is the same as `loadGoals`/`saveGoals`.

---

## Constant data

### `mockSubjects`

Map of CSAT subjects under the 2022 revised curriculum:
```dart
{
  '공통': ['국어', '수학', '영어', '한국사', '통합사회', '통합과학'],
  '직업탐구': ['성공적인 직업생활'],
  '제2외국어/한문 (택 1)': ['독일어', '프랑스어', ... '한문'],
}
```

### `subjectColors`

Fixed per-subject colors (for charts):
```dart
{'국어': 0xFFE53935, '수학': 0xFF1E88E5, '영어': 0xFF43A047, ...}
```

### `getSubjectColor`

```dart
static int getSubjectColor(String subject)
```

For subjects not in `subjectColors`, a deterministic color is generated as `subject.hashCode | 0xFF000000`.
