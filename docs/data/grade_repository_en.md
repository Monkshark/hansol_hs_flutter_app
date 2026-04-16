# GradeRepository

> 한국어: [grade_repository.md](./grade_repository.md)

> `lib/data/grade_repository.dart` — Grade management Repository interface

Wraps the static methods of [`GradeManager`](grade_manager_en.md) as instance methods and registers them with GetIt DI. Allows mock injection in tests.

---

## Design background

Same pattern as [`AuthRepository`](auth_repository_en.md):
```
GradeManager (static methods, depends on SecureStorage)
    ↑
GradeRepository (instance interface)
    ↑
LocalGradeRepository (delegates to GradeManager)
```

> 📎 [`GradeManager`](grade_manager_en.md) · [`SecureStorageService`](secure_storage_service.md)

Replacing with `MockGradeRepository` in Riverpod Provider tests removes the dependency on sqflite/SharedPreferences/SecureStorage.

---

## `GradeRepository` (abstract class)

```dart
abstract class GradeRepository {
  Future<List<Exam>> loadExams();
  Future<void> saveExams(List<Exam> exams);
  Future<void> addExam(Exam exam);
  Future<void> updateExam(Exam exam);
  Future<void> deleteExam(String id);
  Future<Map<String, double>> loadGoals();
  Future<void> saveGoals(Map<String, double> goals);
  Future<Map<String, double>> loadJeongsiGoals();
  Future<void> saveJeongsiGoals(Map<String, double> goals);
}
```

Extracts every public method of [`GradeManager`](grade_manager_en.md) into the interface. Exam CRUD + early/regular admission goal management.

---

## `LocalGradeRepository` (default implementation)

```dart
class LocalGradeRepository implements GradeRepository {
  const LocalGradeRepository();

  @override
  Future<List<Exam>> loadExams() => GradeManager.loadExams();

  @override
  Future<void> addExam(Exam exam) => GradeManager.addExam(exam);

  @override
  Future<void> deleteExam(String id) => GradeManager.deleteExam(id);

  // ... all remaining methods delegate to GradeManager static methods
}
```

`const` constructor. Every method calls a [`GradeManager`](grade_manager_en.md) static method directly.

---

## GetIt accessor

```dart
GradeRepository get gradeRepository => GetIt.I<GradeRepository>();
```

Registered in `service_locator.dart`:
```dart
getIt.registerLazySingleton<GradeRepository>(
  () => const LocalGradeRepository(),
);
```

---

## Test usage

```dart
// test setUp
await resetServiceLocator();
GetIt.I.registerSingleton<GradeRepository>(MockGradeRepository());
```

If `MockGradeRepository` manages exam data with an in-memory list, [`ExamsNotifier`](../providers/providers.md) can be tested without SecureStorage.
