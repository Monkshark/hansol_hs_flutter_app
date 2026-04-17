import 'package:flutter/material.dart';

class SubjectEntry {
  final String name;
  final TextEditingController rawScoreCtrl;
  final TextEditingController averageCtrl;
  final TextEditingController rankCtrl;
  final TextEditingController standardScoreCtrl;
  final TextEditingController percentileCtrl;
  String? achievement;

  SubjectEntry({
    required this.name,
    TextEditingController? rawScoreCtrl,
    TextEditingController? averageCtrl,
    TextEditingController? rankCtrl,
    TextEditingController? standardScoreCtrl,
    TextEditingController? percentileCtrl,
    this.achievement,
  })  : rawScoreCtrl = rawScoreCtrl ?? TextEditingController(),
        averageCtrl = averageCtrl ?? TextEditingController(),
        rankCtrl = rankCtrl ?? TextEditingController(),
        standardScoreCtrl = standardScoreCtrl ?? TextEditingController(),
        percentileCtrl = percentileCtrl ?? TextEditingController();

  void dispose() {
    rawScoreCtrl.dispose();
    averageCtrl.dispose();
    rankCtrl.dispose();
    standardScoreCtrl.dispose();
    percentileCtrl.dispose();
  }
}
