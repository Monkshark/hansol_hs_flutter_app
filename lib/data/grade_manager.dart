import 'dart:convert';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 과목별 점수 데이터 모델
///
/// 내신(원점수/평균/등급/성취도)과 모의고사(백분위/표준점수/등급)를
/// 하나의 구조체로 통합 관리한다.
class SubjectScore {
  final String subject;
  final int? rawScore;
  final int? rank;
  final double? percentile;
  final double? standardScore;
  final double? average;
  final String? achievement; // 성취도 A~E (내신 5등급제 병기)

  SubjectScore({
    required this.subject,
    this.rawScore,
    this.rank,
    this.percentile,
    this.standardScore,
    this.average,
    this.achievement,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    if (rawScore != null) 'rawScore': rawScore,
    if (rank != null) 'rank': rank,
    if (percentile != null) 'percentile': percentile,
    if (standardScore != null) 'standardScore': standardScore,
    if (average != null) 'average': average,
    if (achievement != null) 'achievement': achievement,
  };

  factory SubjectScore.fromJson(Map<String, dynamic> json) => SubjectScore(
    subject: json['subject'],
    rawScore: json['rawScore'],
    rank: json['rank'],
    percentile: json['percentile'] != null ? (json['percentile'] as num).toDouble() : null,
    standardScore: json['standardScore'] != null ? (json['standardScore'] as num).toDouble() : null,
    average: json['average'] != null ? (json['average'] as num).toDouble() : null,
    achievement: json['achievement'],
  );

  /// 내신 등급 비율 (5등급제)
  static const rankCutoffs = {1: '상위 10%', 2: '상위 34%', 3: '상위 66%', 4: '상위 90%', 5: '하위 10%'};
  static const achievements = ['A', 'B', 'C', 'D', 'E'];
}

/// 시험 데이터 모델 (중간/기말/모의/사설모의)
class Exam {
  final String id;
  final String type;        // 'midterm', 'final', 'mock', 'private_mock'
  final int year;
  final int semester;       // 1 or 2
  final int grade;          // 1, 2, 3
  final String? mockLabel;  // 모의: '3월', '6월' 등 / 사설: 직접 입력
  final List<SubjectScore> scores;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.type,
    required this.year,
    required this.semester,
    required this.grade,
    this.mockLabel,
    required this.scores,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Korean display name (for backward compat)
  String get displayName {
    switch (type) {
      case 'midterm': return '$year ${semester}학기 중간고사';
      case 'final': return '$year ${semester}학기 기말고사';
      case 'mock': return '$year $mockLabel 모의고사';
      case 'private_mock': return '$year $mockLabel';
      default: return '$year 시험';
    }
  }

  /// Localized display name (for UI)
  String localizedDisplayName(AppLocalizations l) {
    switch (type) {
      case 'midterm': return '$year ${l.data_midterm(semester.toString())}';
      case 'final': return '$year ${l.data_final(semester.toString())}';
      case 'mock': return l.data_mock(year.toString(), mockLabel ?? '');
      case 'private_mock': return l.data_privateMock(year.toString(), mockLabel ?? '');
      default: return l.data_exam(year.toString());
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'year': year,
    'semester': semester,
    'grade': grade,
    'mockLabel': mockLabel,
    'scores': scores.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
  };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'],
    type: json['type'],
    year: json['year'],
    semester: json['semester'],
    grade: json['grade'],
    mockLabel: json['mockLabel'],
    scores: (json['scores'] as List).map((s) => SubjectScore.fromJson(s)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
  );
}

/// 성적 관리 (로컬 전용)
///
/// - 모의고사/내신 성적 CRUD
/// - 과목별 목표 등급 관리
/// - SharedPreferences JSON 저장 (서버 저장 안 함)
class GradeManager {
  static const _examsKey = 'grade_exams';
  static const _goalsKey = 'grade_goals';
  static const _goalsJeongsiKey = 'grade_goals_jeongsi';

  /// 수능 등급컷 (백분위 → 등급)
  static int percentileToRank(double percentile) {
    if (percentile >= 96) return 1;
    if (percentile >= 89) return 2;
    if (percentile >= 77) return 3;
    if (percentile >= 60) return 4;
    if (percentile >= 40) return 5;
    if (percentile >= 23) return 6;
    if (percentile >= 11) return 7;
    if (percentile >= 4) return 8;
    return 9;
  }

  /// 2022 개정 교육과정 수능 과목 (2028학년도~)
  static const mockSubjects = {
    '공통': ['국어', '수학', '영어', '한국사', '통합사회', '통합과학'],
    '직업탐구': ['성공적인 직업생활'],
    '제2외국어/한문 (택 1)': ['독일어', '프랑스어', '스페인어', '중국어', '일본어', '러시아어', '아랍어', '베트남어', '한문'],
  };

  /// 과목별 고정 색상
  static const subjectColors = <String, int>{
    '국어': 0xFFE53935,
    '수학': 0xFF1E88E5,
    '영어': 0xFF43A047,
    '한국사': 0xFF8E24AA,
    '통합사회': 0xFFFF8F00,
    '통합과학': 0xFF00897B,
    '성공적인 직업생활': 0xFF6D4C41,
    '독일어': 0xFF5C6BC0,
    '프랑스어': 0xFF42A5F5,
    '스페인어': 0xFFEF5350,
    '중국어': 0xFFFF7043,
    '일본어': 0xFFEC407A,
    '러시아어': 0xFF26A69A,
    '아랍어': 0xFF8D6E63,
    '베트남어': 0xFF66BB6A,
    '한문': 0xFF78909C,
  };

  static int getSubjectColor(String subject) {
    return subjectColors[subject] ?? subject.hashCode | 0xFF000000;
  }

  static Future<List<Exam>> loadExams() async {
    // SharedPreferences → SecureStorage 일회성 마이그레이션
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService.migrateFromPlain(
      key: SecureStorageService.keyGradeExams,
      oldValue: prefs.getString(_examsKey),
      onMigrated: () async => prefs.remove(_examsKey),
    );
    final json = await SecureStorageService.read(SecureStorageService.keyGradeExams);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Exam.fromJson(e)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> saveExams(List<Exam> exams) async {
    await SecureStorageService.write(
      SecureStorageService.keyGradeExams,
      jsonEncode(exams.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> addExam(Exam exam) async {
    final exams = await loadExams();
    exams.add(exam);
    await saveExams(exams);
  }

  static Future<void> updateExam(Exam exam) async {
    final exams = await loadExams();
    final idx = exams.indexWhere((e) => e.id == exam.id);
    if (idx != -1) {
      exams[idx] = exam;
      await saveExams(exams);
    }
  }

  static Future<void> deleteExam(String id) async {
    final exams = await loadExams();
    exams.removeWhere((e) => e.id == id);
    await saveExams(exams);
  }

  /// 과목별 목표 등급
  static Future<Map<String, double>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService.migrateFromPlain(
      key: SecureStorageService.keyGradeGoals,
      oldValue: prefs.getString(_goalsKey),
      onMigrated: () async => prefs.remove(_goalsKey),
    );
    final json = await SecureStorageService.read(SecureStorageService.keyGradeGoals);
    if (json == null) return {};
    final raw = jsonDecode(json) as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  static Future<void> saveGoals(Map<String, double> goals) async {
    await SecureStorageService.write(SecureStorageService.keyGradeGoals, jsonEncode(goals));
  }

  /// 정시 목표 (백분위 기준, 정수)
  static Future<Map<String, double>> loadJeongsiGoals() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService.migrateFromPlain(
      key: SecureStorageService.keyGradeJeongsiGoals,
      oldValue: prefs.getString(_goalsJeongsiKey),
      onMigrated: () async => prefs.remove(_goalsJeongsiKey),
    );
    final json = await SecureStorageService.read(SecureStorageService.keyGradeJeongsiGoals);
    if (json == null) return {};
    final raw = jsonDecode(json) as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  static Future<void> saveJeongsiGoals(Map<String, double> goals) async {
    await SecureStorageService.write(SecureStorageService.keyGradeJeongsiGoals, jsonEncode(goals));
  }
}
