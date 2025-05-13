import 'package:flutter/material.dart';

class PeriodText extends StatefulWidget {
  final String startTime;
  final String endTime;

  const PeriodText({
    Key? key,
    required this.startTime,
    required this.endTime,
  }) : super(key: key);

  @override
  State<PeriodText> createState() => _PeriodTextState();
}

class _PeriodTextState extends State<PeriodText> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
