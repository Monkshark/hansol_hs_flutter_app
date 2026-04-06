import 'dart:convert';
import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

/// 성적 관리 (로컬 전용)
///
/// - 모의고사/내신 성적 CRUD
/// - 과목별 목표 등급 관리
/// - SharedPreferences JSON 저장 (서버 저장 안 함)
class SubjectScore {
  final String subject;
  final int? rawScore;
  final int? rank;
  final double? percentile;
  final double? standardScore;
  final double? average;

  SubjectScore({
    required this.subject,
    this.rawScore,
    this.rank,
    this.percentile,
    this.standardScore,
    this.average,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    if (rawScore != null) 'rawScore': rawScore,
    if (rank != null) 'rank': rank,
    if (percentile != null) 'percentile': percentile,
    if (standardScore != null) 'standardScore': standardScore,
    if (average != null) 'average': average,
  };

  factory SubjectScore.fromJson(Map<String, dynamic> json) => SubjectScore(
    subject: json['subject'],
    rawScore: json['rawScore'],
    rank: json['rank'],
    percentile: json['percentile'] != null ? (json['percentile'] as num).toDouble() : null,
    standardScore: json['standardScore'] != null ? (json['standardScore'] as num).toDouble() : null,
    average: json['average'] != null ? (json['average'] as num).toDouble() : null,
  );
}

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

  String get displayName {
    switch (type) {
      case 'midterm': return '$year ${semester}학기 중간고사';
      case 'final': return '$year ${semester}학기 기말고사';
      case 'mock': return '$year $mockLabel 모의고사';
      case 'private_mock': return '$year $mockLabel';
      default: return '$year 시험';
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

class GradeManager {
  static const _examsKey = 'grade_exams';
  static const _goalsKey = 'grade_goals';

  // 2022 개정 수능 과목
  static const mockSubjects = {
    '공통': ['국어', '수학', '영어', '한국사'],
    '수학 선택': ['미적분II', '기하'],
    '사회탐구': ['통합사회1', '통합사회2', '한국지리', '세계지리', '동아시아사', '세계사', '경제', '정치와 법', '사회·문화', '윤리와 사상', '생활과 윤리'],
    '과학탐구': ['통합과학1', '통합과학2', '물리학', '화학', '생명과학', '지구과학'],
    '제2외국어/한문': ['일본어', '중국어', '프랑스어', '독일어', '스페인어', '러시아어', '아랍어', '베트남어', '한문'],
  };

  // 과목별 고정 색상
  static const subjectColors = <String, int>{
    '국어': 0xFFE53935,
    '수학': 0xFF1E88E5,
    '영어': 0xFF43A047,
    '한국사': 0xFF8E24AA,
    '미적분II': 0xFF1565C0,
    '기하': 0xFF0277BD,
    '통합사회1': 0xFFFF8F00,
    '통합사회2': 0xFFF9A825,
    '한국지리': 0xFFEF6C00,
    '세계지리': 0xFFE65100,
    '동아시아사': 0xFFD84315,
    '세계사': 0xFFBF360C,
    '경제': 0xFF4E342E,
    '정치와 법': 0xFF5D4037,
    '사회·문화': 0xFF6D4C41,
    '윤리와 사상': 0xFF795548,
    '생활과 윤리': 0xFF8D6E63,
    '통합과학1': 0xFF00897B,
    '통합과학2': 0xFF00796B,
    '물리학': 0xFF00ACC1,
    '화학': 0xFF039BE5,
    '생명과학': 0xFF7CB342,
    '지구과학': 0xFF558B2F,
  };

  static int getSubjectColor(String subject) {
    return subjectColors[subject] ?? subject.hashCode | 0xFF000000;
  }

  static Future<List<Exam>> loadExams() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_examsKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => Exam.fromJson(e)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  static Future<void> saveExams(List<Exam> exams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_examsKey, jsonEncode(exams.map((e) => e.toJson()).toList()));
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

  // 과목별 목표 등급
  static Future<Map<String, int>> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_goalsKey);
    if (json == null) return {};
    return Map<String, int>.from(jsonDecode(json));
  }

  static Future<void> saveGoals(Map<String, int> goals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalsKey, jsonEncode(goals));
  }
}
