import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/grade_manager.dart';

/// 성적 관리 Repository (인스턴스 기반)
///
/// `GradeManager`의 정적 메서드를 인스턴스 메서드로 감싸 GetIt에 등록한다.
/// 테스트에서 `MockGradeRepository`로 교체 가능 — Riverpod Provider 테스트에서
/// `ProviderScope.overrides`와 결합해 sqflite/SharedPreferences 의존을 제거한다.
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

class LocalGradeRepository implements GradeRepository {
  const LocalGradeRepository();

  @override
  Future<List<Exam>> loadExams() => GradeManager.loadExams();

  @override
  Future<void> saveExams(List<Exam> exams) => GradeManager.saveExams(exams);

  @override
  Future<void> addExam(Exam exam) => GradeManager.addExam(exam);

  @override
  Future<void> updateExam(Exam exam) => GradeManager.updateExam(exam);

  @override
  Future<void> deleteExam(String id) => GradeManager.deleteExam(id);

  @override
  Future<Map<String, double>> loadGoals() => GradeManager.loadGoals();

  @override
  Future<void> saveGoals(Map<String, double> goals) =>
      GradeManager.saveGoals(goals);

  @override
  Future<Map<String, double>> loadJeongsiGoals() =>
      GradeManager.loadJeongsiGoals();

  @override
  Future<void> saveJeongsiGoals(Map<String, double> goals) =>
      GradeManager.saveJeongsiGoals(goals);
}

GradeRepository get gradeRepository => GetIt.I<GradeRepository>();
