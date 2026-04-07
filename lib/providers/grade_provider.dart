import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/grade_manager.dart';

/// 성적 관리 Riverpod Provider
///
/// - [examsProvider]: 전체 시험 목록 (AsyncNotifier)
/// - [goalsProvider]: 수시 목표 등급
/// - [jeongsiGoalsProvider]: 정시 목표 백분위
/// - [examsByTypeProvider]: 수시/정시 분리된 파생 Provider

/// 0 = 수시 (midterm/final), 1 = 정시 (mock/private_mock)
typedef ExamTab = int;

/// 시험 목록 AsyncNotifier
///
/// 모든 mutator는 `await future`로 초기 build 완료를 보장한 뒤
/// 직접 state를 갱신한다 (invalidateSelf race condition 회피).
class ExamsNotifier extends AsyncNotifier<List<Exam>> {
  @override
  Future<List<Exam>> build() => GradeManager.loadExams();

  Future<void> add(Exam exam) async {
    final current = await future;
    await GradeManager.addExam(exam);
    state = AsyncData([...current, exam]);
  }

  Future<void> updateExam(Exam exam) async {
    final current = await future;
    await GradeManager.updateExam(exam);
    state = AsyncData([
      for (final e in current) if (e.id == exam.id) exam else e,
    ]);
  }

  Future<void> delete(String id) async {
    final current = await future;
    state = AsyncData(current.where((e) => e.id != id).toList());
    await GradeManager.deleteExam(id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => GradeManager.loadExams());
  }
}

final examsProvider = AsyncNotifierProvider<ExamsNotifier, List<Exam>>(
  ExamsNotifier.new,
);

/// 탭별로 필터링된 시험 목록 (파생 Provider)
final examsByTypeProvider = Provider.family<List<Exam>, ExamTab>((ref, tab) {
  final exams = ref.watch(examsProvider).valueOrNull ?? [];
  if (tab == 0) {
    return exams.where((e) => e.type == 'midterm' || e.type == 'final').toList();
  }
  return exams.where((e) => e.type == 'mock' || e.type == 'private_mock').toList();
});

/// 수시 목표 등급
class GoalsNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() => GradeManager.loadGoals();

  Future<void> save(Map<String, double> goals) async {
    await future; // 초기 build 완료 보장
    await GradeManager.saveGoals(goals);
    state = AsyncData(goals);
  }
}

final goalsProvider = AsyncNotifierProvider<GoalsNotifier, Map<String, double>>(
  GoalsNotifier.new,
);

/// 정시 목표 백분위
class JeongsiGoalsNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() => GradeManager.loadJeongsiGoals();

  Future<void> save(Map<String, double> goals) async {
    await future;
    await GradeManager.saveJeongsiGoals(goals);
    state = AsyncData(goals);
  }
}

final jeongsiGoalsProvider =
    AsyncNotifierProvider<JeongsiGoalsNotifier, Map<String, double>>(
  JeongsiGoalsNotifier.new,
);
