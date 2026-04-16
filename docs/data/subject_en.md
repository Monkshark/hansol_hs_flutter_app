# Subject

> 한국어: [subject.md](./subject.md)

> `lib/data/subject.dart` — Subject data model (freezed)

Based on `@freezed`, but overrides `==`/`hashCode` with custom implementations. JSON serialization is code-generated (`subject.g.dart`).

---

## Fields

```dart
@freezed
class Subject with _$Subject {
  const factory Subject({
    required String subjectName,   // Subject name (e.g., 'Korean', 'Math')
    required int subjectClass,     // Class number. -1 for special-room subjects
    String? category,              // Subject category (configured in admin Firestore)
    @Default(false) bool isOriginal, // Whether the subject was registered by an admin
  }) = _Subject;
}
```

- `subjectClass`: `CLASS_NM` value from the NEIS timetable. `-1` for special rooms (no class number)
- `category`: Classification fetched by `TimetableDataApi.getSubjectsFromAdminFirestore`
- `isOriginal`: true for admin-registered subjects, false for NEIS auto-extracted ones

---

## Equality (custom)

```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is Subject &&
        runtimeType == other.runtimeType &&
        subjectName == other.subjectName &&
        subjectClass == other.subjectClass;

@override
int get hashCode => subjectName.hashCode ^ subjectClass.hashCode;
```

Equality is determined by the combination of `subjectName` + `subjectClass`. `category` and `isOriginal` are excluded from comparison.

**Reason**: When `TimetableDataApi.getAllSubjectCombinations` puts Subjects into a Set to deduplicate, any two with the same subject+class should be treated as the same subject.

---

## JSON serialization

```dart
factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);
```

Used by [`SubjectDataManager`](subject_data_manager.md) when saving/restoring to SharedPreferences/Firestore.

---

## Usage

| Location | Purpose |
|----------|---------|
| [`TimetableDataApi`](../api/timetable_data_api.md)`.getAllSubjectCombinations` | Extracts subject+class combinations from the NEIS timetable and deduplicates with a Set |
| [`TimetableDataApi`](../api/timetable_data_api.md)`.getCustomTimeTable` | Builds a custom timetable from a user-selected Subject list |
| [`TimetableDataApi`](../api/timetable_data_api.md)`.getSubjectsFromAdminFirestore` | Queries admin-registered subjects from Firestore |
| [`SubjectDataManager`](subject_data_manager.md) | Local/Firestore storage for elective subjects |
| `TimetableSelectScreen` | Displays the Subject list in the subject-selection UI |
