import 'package:flutter/material.dart';
import 'package:hansol_high_school/widgets/subject/subject_card.dart';
import 'package:hansol_high_school/widgets/subject/subject_card_stacker.dart';

class TimetableSelectScreen extends StatefulWidget {
  const TimetableSelectScreen({Key? key}) : super(key: key);

  @override
  State<TimetableSelectScreen> createState() => _TimetableSelectScreenState();
}

class _TimetableSelectScreenState extends State<TimetableSelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Color(0xffE0E0E0),
          appBar: AppBar(
            backgroundColor: Color(0xffE0E0E0),
            title: const Text('선택과목 시간표 설정'),
          ),
          body: Column(
            children: [
              Center(
                child: SubjectCardStacker(
                  cards: [
                    SubjectCard(subjectName: '생명과학 I', classNumber: 1),
                    SubjectCard(subjectName: '생명과학 I', classNumber: 2),
                    SubjectCard(subjectName: '생명과학 I', classNumber: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
