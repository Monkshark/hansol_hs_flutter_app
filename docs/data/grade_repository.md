# GradeRepository

> `lib/data/grade_repository.dart` — 성적 관리 Repository 인터페이스

[`GradeManager`](grade_manager.md)의 정적 메서드를 인스턴스 메서드로 감싸 GetIt DI에 등록. 테스트에서 mock 주입 가능.

---

## 설계 배경

[`AuthRepository`](auth_repository.md)와 동일한 패턴:
```
GradeManager (정적 메서드, SecureStorage 의존)
    ↑
GradeRepository (인스턴스 인터페이스)
    ↑
LocalGradeRepository (GradeManager에 위임)
```

> [`GradeManager`](grade_manager.md) · [`SecureStorageService`](secure_storage_service.md)

Riverpod Provider 테스트에서 `MockGradeRepository`로 교체하면 sqflite/SharedPreferences/SecureStorage 의존을 제거할 수 있음.

---

## `GradeRepository` (추상 클래스)

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

[`GradeManager`](grade_manager.md)의 모든 public 메서드를 인터페이스로 추출. 시험 CRUD + 수시/정시 목표 관리.

---

## `LocalGradeRepository` (기본 구현)

```dart
class LocalGradeRepository implements GradeRepository {
  const LocalGradeRepository();

  @override
  Future<List<Exam>> loadExams() => GradeManager.loadExams();

  @override
  Future<void> addExam(Exam exam) => GradeManager.addExam(exam);

  @override
  Future<void> deleteExam(String id) => GradeManager.deleteExam(id);

  // ... 나머지 모두 GradeManager 정적 메서드에 위임
}
```

`const` 생성자. 모든 메서드가 `GradeManager` 정적 메서드를 그대로 호출.

---

## GetIt 접근자

```dart
GradeRepository get gradeRepository => GetIt.I<GradeRepository>();
```

`service_locator.dart`에서 등록:
```dart
getIt.registerLazySingleton<GradeRepository>(
  () => const LocalGradeRepository(),
);
```

---

## 테스트 활용

```dart
// test setUp
await resetServiceLocator();
GetIt.I.registerSingleton<GradeRepository>(MockGradeRepository());
```

`MockGradeRepository`에서 인메모리 리스트로 시험 데이터를 관리하면 SecureStorage 없이 [`ExamsNotifier`](../providers/providers.md) 테스트 가능.
