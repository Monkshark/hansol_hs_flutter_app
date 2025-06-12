import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hansol_high_school/data/subject.dart';

class SubjectDataManager {
  static const String _selectedSubjectsKeyPrefix = 'selected_subjects_grade_';

  static Future<List<Subject>> loadSelectedSubjects(int grade) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_selectedSubjectsKeyPrefix$grade');
    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList.map((json) => Subject.fromJson(json)).toList();
    }
    return [];
  }

  static Future<void> saveSelectedSubjects(
      int grade, List<Subject> selectedSubjects) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = selectedSubjects.map((s) => s.toJson()).toList();
    await prefs.setString(
        '$_selectedSubjectsKeyPrefix$grade', jsonEncode(jsonList));
  }
}
