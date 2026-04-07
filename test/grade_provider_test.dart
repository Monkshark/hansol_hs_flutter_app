import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:hansol_high_school/providers/grade_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod Provider 단위 테스트
///
/// `ProviderContainer`로 위젯 트리 없이 Provider 동작을 검증한다.
/// SharedPreferences는 mock 초기화로 격리.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    return container;
  }

  group('examsProvider', () {
    test('초기 상태는 빈 리스트', () async {
      final container = makeContainer();
      final exams = await container.read(examsProvider.future);
      expect(exams, isEmpty);
    });

    test('add → 상태 자동 갱신', () async {
      final container = makeContainer();
      await container.read(examsProvider.future); // 초기 로드

      await container.read(examsProvider.notifier).add(Exam(
            id: '1',
            type: 'midterm',
            year: 2026,
            semester: 1,
            grade: 2,
            scores: [SubjectScore(subject: '국어', rawScore: 88)],
          ));

      final exams = await container.read(examsProvider.future);
      expect(exams.length, 1);
      expect(exams.first.id, '1');
    });

    test('delete → 낙관적 업데이트', () async {
      final container = makeContainer();
      await container.read(examsProvider.notifier).add(Exam(
            id: 'a',
            type: 'midterm',
            year: 2026,
            semester: 1,
            grade: 2,
            scores: [],
          ));
      await container.read(examsProvider.notifier).add(Exam(
            id: 'b',
            type: 'final',
            year: 2026,
            semester: 1,
            grade: 2,
            scores: [],
          ));

      await container.read(examsProvider.notifier).delete('a');

      final exams = container.read(examsProvider).valueOrNull ?? [];
      expect(exams.length, 1);
      expect(exams.first.id, 'b');
    });
  });

  group('examsByTypeProvider (파생 Provider)', () {
    test('수시 탭 (0) → midterm/final만 반환', () async {
      final container = makeContainer();

      await container.read(examsProvider.notifier).add(Exam(
            id: '1', type: 'midterm', year: 2026, semester: 1, grade: 2, scores: [],
          ));
      await container.read(examsProvider.notifier).add(Exam(
            id: '2', type: 'mock', year: 2026, semester: 1, grade: 2, scores: [],
          ));
      await container.read(examsProvider.notifier).add(Exam(
            id: '3', type: 'final', year: 2026, semester: 1, grade: 2, scores: [],
          ));

      final susi = container.read(examsByTypeProvider(0));
      expect(susi.length, 2);
      expect(susi.map((e) => e.id), containsAll(['1', '3']));
    });

    test('정시 탭 (1) → mock/private_mock만 반환', () async {
      final container = makeContainer();

      await container.read(examsProvider.notifier).add(Exam(
            id: '1', type: 'midterm', year: 2026, semester: 1, grade: 2, scores: [],
          ));
      await container.read(examsProvider.notifier).add(Exam(
            id: '2', type: 'mock', year: 2026, semester: 1, grade: 2, scores: [],
          ));
      await container.read(examsProvider.notifier).add(Exam(
            id: '3', type: 'private_mock', year: 2026, semester: 1, grade: 3,
            mockLabel: '메가스터디 4월', scores: [],
          ));

      final jeongsi = container.read(examsByTypeProvider(1));
      expect(jeongsi.length, 2);
      expect(jeongsi.map((e) => e.id), containsAll(['2', '3']));
    });
  });

  group('goalsProvider / jeongsiGoalsProvider', () {
    test('수시/정시 목표는 분리 저장', () async {
      final container = makeContainer();

      await container.read(goalsProvider.notifier).save({'국어': 2.0});
      await container.read(jeongsiGoalsProvider.notifier).save({'국어': 90.0});

      final susi = await container.read(goalsProvider.future);
      final jeongsi = await container.read(jeongsiGoalsProvider.future);

      expect(susi['국어'], 2.0);
      expect(jeongsi['국어'], 90.0);
    });

    test('save 호출 후 상태 자동 반영', () async {
      final container = makeContainer();
      await container.read(goalsProvider.future);
      await container.read(goalsProvider.notifier).save({'수학': 1.0, '영어': 1.5});

      final state = container.read(goalsProvider).valueOrNull;
      expect(state, isNotNull);
      expect(state!['수학'], 1.0);
      expect(state['영어'], 1.5);
    });
  });
}
