import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/grade_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('GradeManager.percentileToRank', () {
    test('1등급 (>= 96)', () {
      expect(GradeManager.percentileToRank(100), 1);
      expect(GradeManager.percentileToRank(96), 1);
    });

    test('2등급 (89-95)', () {
      expect(GradeManager.percentileToRank(95.99), 2);
      expect(GradeManager.percentileToRank(89), 2);
    });

    test('3등급 (77-88)', () {
      expect(GradeManager.percentileToRank(88), 3);
      expect(GradeManager.percentileToRank(77), 3);
    });

    test('4등급 (60-76)', () {
      expect(GradeManager.percentileToRank(76), 4);
      expect(GradeManager.percentileToRank(60), 4);
    });

    test('5등급 (40-59)', () {
      expect(GradeManager.percentileToRank(59), 5);
      expect(GradeManager.percentileToRank(40), 5);
    });

    test('6등급 (23-39)', () {
      expect(GradeManager.percentileToRank(39), 6);
      expect(GradeManager.percentileToRank(23), 6);
    });

    test('7등급 (11-22)', () {
      expect(GradeManager.percentileToRank(22), 7);
      expect(GradeManager.percentileToRank(11), 7);
    });

    test('8등급 (4-10)', () {
      expect(GradeManager.percentileToRank(10), 8);
      expect(GradeManager.percentileToRank(4), 8);
    });

    test('9등급 (< 4)', () {
      expect(GradeManager.percentileToRank(3.99), 9);
      expect(GradeManager.percentileToRank(0), 9);
    });
  });

  group('GradeManager.getSubjectColor', () {
    test('등록된 과목은 고정 색상 반환', () {
      expect(GradeManager.getSubjectColor('국어'), 0xFFE53935);
      expect(GradeManager.getSubjectColor('수학'), 0xFF1E88E5);
      expect(GradeManager.getSubjectColor('영어'), 0xFF43A047);
    });

    test('미등록 과목은 hashCode 기반 색상 반환', () {
      final color = GradeManager.getSubjectColor('미등록과목');
      // 알파 채널이 0xFF인지 (불투명)
      expect(color & 0xFF000000, 0xFF000000);
    });
  });

  group('SubjectScore JSON 직렬화', () {
    test('내신 점수 round-trip', () {
      final original = SubjectScore(
        subject: '국어',
        rawScore: 92,
        rank: 2,
        average: 78.5,
        achievement: 'B',
      );
      final json = original.toJson();
      final restored = SubjectScore.fromJson(json);

      expect(restored.subject, '국어');
      expect(restored.rawScore, 92);
      expect(restored.rank, 2);
      expect(restored.average, 78.5);
      expect(restored.achievement, 'B');
      expect(restored.percentile, isNull);
    });

    test('모의고사 점수 round-trip', () {
      final original = SubjectScore(
        subject: '수학',
        percentile: 87.5,
        standardScore: 132,
        rank: 3,
      );
      final json = original.toJson();
      final restored = SubjectScore.fromJson(json);

      expect(restored.subject, '수학');
      expect(restored.percentile, 87.5);
      expect(restored.standardScore, 132);
      expect(restored.rank, 3);
      expect(restored.rawScore, isNull);
    });

    test('null 필드는 toJson에서 제외', () {
      final score = SubjectScore(subject: '영어', rank: 1);
      final json = score.toJson();
      expect(json.containsKey('rawScore'), false);
      expect(json.containsKey('percentile'), false);
      expect(json.containsKey('average'), false);
    });
  });

  group('Exam JSON 직렬화 + displayName', () {
    test('중간고사 displayName', () {
      final exam = Exam(
        id: '1',
        type: 'midterm',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [],
      );
      expect(exam.displayName, '2026 1학기 중간고사');
    });

    test('기말고사 displayName', () {
      final exam = Exam(
        id: '2',
        type: 'final',
        year: 2026,
        semester: 2,
        grade: 3,
        scores: [],
      );
      expect(exam.displayName, '2026 2학기 기말고사');
    });

    test('모의고사 displayName', () {
      final exam = Exam(
        id: '3',
        type: 'mock',
        year: 2026,
        semester: 1,
        grade: 3,
        mockLabel: '6월',
        scores: [],
      );
      expect(exam.displayName, '2026 6월 모의고사');
    });

    test('사설모의 displayName', () {
      final exam = Exam(
        id: '4',
        type: 'private_mock',
        year: 2026,
        semester: 1,
        grade: 3,
        mockLabel: '메가스터디 3월',
        scores: [],
      );
      expect(exam.displayName, '2026 메가스터디 3월');
    });

    test('Exam round-trip', () {
      final original = Exam(
        id: 'test',
        type: 'midterm',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [
          SubjectScore(subject: '국어', rawScore: 88, rank: 2, average: 75, achievement: 'B'),
          SubjectScore(subject: '수학', rawScore: 95, rank: 1, average: 70, achievement: 'A'),
        ],
        createdAt: DateTime(2026, 5, 1),
      );
      final json = original.toJson();
      final restored = Exam.fromJson(json);

      expect(restored.id, 'test');
      expect(restored.type, 'midterm');
      expect(restored.scores.length, 2);
      expect(restored.scores[0].subject, '국어');
      expect(restored.scores[1].rawScore, 95);
      expect(restored.createdAt, DateTime(2026, 5, 1));
    });
  });

  group('GradeManager CRUD (SharedPreferences mock)', () {
    test('빈 저장소는 빈 리스트 반환', () async {
      final exams = await GradeManager.loadExams();
      expect(exams, isEmpty);
    });

    test('addExam → loadExams', () async {
      final exam = Exam(
        id: 'a1',
        type: 'midterm',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [SubjectScore(subject: '국어', rawScore: 90)],
      );
      await GradeManager.addExam(exam);

      final loaded = await GradeManager.loadExams();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'a1');
      expect(loaded.first.scores.first.subject, '국어');
    });

    test('updateExam → 기존 항목 교체', () async {
      final original = Exam(
        id: 'u1',
        type: 'midterm',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [SubjectScore(subject: '수학', rawScore: 80)],
      );
      await GradeManager.addExam(original);

      final updated = Exam(
        id: 'u1',
        type: 'midterm',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [SubjectScore(subject: '수학', rawScore: 95)],
        createdAt: original.createdAt,
      );
      await GradeManager.updateExam(updated);

      final loaded = await GradeManager.loadExams();
      expect(loaded.length, 1);
      expect(loaded.first.scores.first.rawScore, 95);
    });

    test('deleteExam → 항목 제거', () async {
      await GradeManager.addExam(Exam(
        id: 'd1',
        type: 'midterm',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [],
      ));
      await GradeManager.addExam(Exam(
        id: 'd2',
        type: 'final',
        year: 2026,
        semester: 1,
        grade: 2,
        scores: [],
      ));

      await GradeManager.deleteExam('d1');
      final loaded = await GradeManager.loadExams();
      expect(loaded.length, 1);
      expect(loaded.first.id, 'd2');
    });

    test('수시 목표 저장/로드', () async {
      await GradeManager.saveGoals({'국어': 2.0, '수학': 1.5});
      final loaded = await GradeManager.loadGoals();
      expect(loaded['국어'], 2.0);
      expect(loaded['수학'], 1.5);
    });

    test('정시 목표 저장/로드 (수시와 분리)', () async {
      await GradeManager.saveGoals({'국어': 2.0});
      await GradeManager.saveJeongsiGoals({'국어': 90.0});

      final susi = await GradeManager.loadGoals();
      final jeongsi = await GradeManager.loadJeongsiGoals();

      expect(susi['국어'], 2.0);
      expect(jeongsi['국어'], 90.0);
    });
  });

  group('필수 상수', () {
    test('mockSubjects 그룹 구조', () {
      expect(GradeManager.mockSubjects['공통'], contains('국어'));
      expect(GradeManager.mockSubjects['공통'], contains('수학'));
      expect(GradeManager.mockSubjects['공통'], contains('영어'));
      expect(GradeManager.mockSubjects['공통'], contains('통합사회'));
      expect(GradeManager.mockSubjects['공통'], contains('통합과학'));
      expect(GradeManager.mockSubjects.containsKey('직업탐구'), true);
      expect(GradeManager.mockSubjects.containsKey('제2외국어/한문 (택 1)'), true);
    });

    test('rankCutoffs 5등급제', () {
      expect(SubjectScore.rankCutoffs.length, 5);
      expect(SubjectScore.rankCutoffs[1], '상위 10%');
      expect(SubjectScore.rankCutoffs[5], '하위 10%');
    });

    test('성취도 5단계 (A~E)', () {
      expect(SubjectScore.achievements, ['A', 'B', 'C', 'D', 'E']);
    });
  });
}
