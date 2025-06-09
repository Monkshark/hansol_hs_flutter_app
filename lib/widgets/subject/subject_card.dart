import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/device.dart';

class SubjectCard extends StatelessWidget {
  final String subjectName;
  final int classNumber;
  final bool checked;
  final ValueChanged<bool?>? onCheck;

  const SubjectCard({
    Key? key,
    required this.subjectName,
    required this.classNumber,
    this.checked = false,
    this.onCheck,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
      child: Container(
        width: Device.getWidth(80),
        height: Device.getHeight(15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$subjectName\n${classNumber}반',
                style: TextStyle(
                  fontSize: Device.getWidth(3.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: onCheck,
            ),
          ],
        ),
      ),
    );
  }
}
