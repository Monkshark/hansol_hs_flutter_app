import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/subject.dart';

class SubjectDataManager {
  static const String _selectedSubjectsKeyPrefix = 'selected_subjects_grade_';

  static Future<List<Subject>> loadSelectedSubjects(int grade) async {
    // 1. 로컬 캐시 먼저
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('$_selectedSubjectsKeyPrefix$grade');
    List<Subject> localSubjects = [];
    if (jsonString != null) {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      localSubjects = jsonList.map((json) => Subject.fromJson(json)).toList();
    }

    // 2. 로그인 상태면 Firestore에서도 불러오기 (로컬이 비어있을 때)
    if (localSubjects.isEmpty && AuthService.isLoggedIn) {
      try {
        final uid = AuthService.currentUser!.uid;
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('subjects')
            .doc('grade_$grade')
            .get();

        if (doc.exists && doc.data() != null) {
          final list = doc.data()!['subjects'] as List<dynamic>?;
          if (list != null && list.isNotEmpty) {
            localSubjects = list.map((s) => Subject.fromJson(s)).toList();
            // 로컬에도 저장
            await _saveLocal(prefs, grade, localSubjects);
            log('SubjectDataManager: loaded ${localSubjects.length} subjects from Firestore for grade $grade');
          }
        }
      } catch (e) {
        log('SubjectDataManager: Firestore load error: $e');
      }
    }

    return localSubjects;
  }

  static Future<void> saveSelectedSubjects(
      int grade, List<Subject> selectedSubjects) async {
    // 1. 로컬 저장
    final prefs = await SharedPreferences.getInstance();
    await _saveLocal(prefs, grade, selectedSubjects);

    // 2. 로그인 상태면 Firestore에도 저장
    if (AuthService.isLoggedIn) {
      try {
        final uid = AuthService.currentUser!.uid;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('subjects')
            .doc('grade_$grade')
            .set({
          'subjects': selectedSubjects.map((s) => s.toJson()).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        log('SubjectDataManager: saved ${selectedSubjects.length} subjects to Firestore for grade $grade');
      } catch (e) {
        log('SubjectDataManager: Firestore save error: $e');
      }
    }
  }

  static Future<void> _saveLocal(
      SharedPreferences prefs, int grade, List<Subject> subjects) async {
    final jsonList = subjects.map((s) => s.toJson()).toList();
    await prefs.setString(
        '$_selectedSubjectsKeyPrefix$grade', jsonEncode(jsonList));
  }
}
