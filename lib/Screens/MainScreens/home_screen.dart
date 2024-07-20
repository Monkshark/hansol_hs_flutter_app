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
              onPressed: () {
                TimetableDataApi.getSubjects(grade: 3);
                log(TimetableDataApi.getCustomTimeTable(userSubjects: [
                  new Subject(subjectName: '문학', subjectClass: 1)
                ], grade: 2.toString())
                    .toString());
              },
              icon: const Icon(Icons.settings),
            ),
          ),
        ],
      ),
    );
  }
}
