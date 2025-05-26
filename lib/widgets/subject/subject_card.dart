import 'package:flutter/material.dart';

class SubjectCard extends StatelessWidget {
  final String subjectName;
  final int classNumber;
  final bool checked;
  final VoidCallback? onCheck;

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
      // elevation: 10,
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
      child: Container(
        width: 340,
        height: 140,
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
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Checkbox(
              value: checked,
              onChanged: (_) => onCheck?.call(),
            ),
          ],
        ),
      ),
    );
  }
}
