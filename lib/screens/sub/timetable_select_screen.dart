import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/subject.dart';
import 'package:hansol_high_school/widgets/subject/subject_card_stacker.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/data/subject_data_manager.dart';

class TimetableSelectScreen extends StatefulWidget {
  const TimetableSelectScreen({Key? key}) : super(key: key);

  @override
  State<TimetableSelectScreen> createState() => _TimetableSelectScreenState();
}

class _TimetableSelectScreenState extends State<TimetableSelectScreen> {
  late Future<Map<String, List<Subject>>> _subjectGroupsFuture;
  List<Subject> selectedSubjects = [];

  @override
  void initState() {
    super.initState();
    final settingData = SettingData();
    final grade = settingData.grade;
    _subjectGroupsFuture = _getSubjectGroups(grade);
    _loadSelectedSubjects(grade);
  }

  Future<void> _loadSelectedSubjects(int grade) async {
    selectedSubjects = await SubjectDataManager.loadSelectedSubjects(grade);
    setState(() {});
  }

  Future<void> _saveSelectedSubjects(int grade) async {
    await SubjectDataManager.saveSelectedSubjects(grade, selectedSubjects);
  }

  Future<Map<String, List<Subject>>> _getSubjectGroups(int grade) async {
    final allSubjects =
        await TimetableDataApi.getAllSubjectCombinations(grade: grade);
    final subjectGroups = <String, List<Subject>>{};
    for (var subject in allSubjects) {
      subjectGroups.putIfAbsent(subject.subjectName, () => []).add(subject);
    }
    return subjectGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffE0E0E0),
      appBar: AppBar(
        backgroundColor: const Color(0xffE0E0E0),
        title: const Text('선택과목 시간표 설정'),
      ),
      body: FutureBuilder<Map<String, List<Subject>>>(
        future: _subjectGroupsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('과목을 불러올 수 없습니다.'));
          } else {
            final settingData = SettingData();
            final subjectGroups = snapshot.data!;
            return ListView.builder(
              itemCount: subjectGroups.length,
              itemBuilder: (context, index) {
                final subjectName = subjectGroups.keys.elementAt(index);
                final subjects = subjectGroups[subjectName]!;
                final selectedSubject = selectedSubjects.firstWhere(
                  (s) => s.subjectName == subjectName,
                  orElse: () => Subject(subjectName: '', subjectClass: -1),
                );
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubjectCardStacker(
                        subjects: subjects,
                        selectedSubject: selectedSubject.subjectName.isNotEmpty
                            ? selectedSubject
                            : null,
                        onSubjectSelected: (subject) {
                          setState(() {
                            selectedSubjects.removeWhere(
                                (s) => s.subjectName == subjectName);
                            if (subject != null) {
                              selectedSubjects.add(subject);
                            }
                          });
                          _saveSelectedSubjects(settingData.grade);
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
