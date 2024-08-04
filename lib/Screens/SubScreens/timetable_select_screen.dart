import 'package:flutter/material.dart';

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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('선택과목 시간표 설정'),
          ),
        ),
      ),
    );
  }
}
