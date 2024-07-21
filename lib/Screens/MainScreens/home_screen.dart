import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/subject.dart';

import '../../API/timetable_data_api.dart';

class HansolHighSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              onPressed: () async {
                await TimetableDataApi.getSubjects(grade: 2);

                List<List<String?>> customTimeTable = await TimetableDataApi.getCustomTimeTable(
                    userSubjects: [
                      Subject(subjectName: '문학', subjectClass: 1),
                      Subject(subjectName: '수학Ⅰ', subjectClass: 1),
                      Subject(subjectName: '물리학Ⅰ', subjectClass: 5),
                      Subject(subjectName: '세계 문제와 미래 사회', subjectClass: 6),
                      Subject(subjectName: '운동과 건강', subjectClass: 1),
                      Subject(subjectName: '정보과학', subjectClass: 1),
                      Subject(subjectName: '자율활동', subjectClass: 1),
                      Subject(subjectName: '화학Ⅰ', subjectClass: 7),
                      Subject(subjectName: '기하', subjectClass: 1),
                      Subject(subjectName: '영어Ⅰ', subjectClass: 1),
                      Subject(subjectName: '지구과학Ⅰ', subjectClass: 6),
                      Subject(subjectName: '진로활동', subjectClass: 1),
                    ],
                    grade: 2.toString(),
                );

                log(customTimeTable.toString());
              },

              icon: const Icon(Icons.settings),
            ),
          ),
        ],
      ),
    );
  }
}
