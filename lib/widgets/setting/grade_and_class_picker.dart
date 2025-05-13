import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class GradeAndClassPickerDialog extends StatefulWidget {
  final int initialGrade;
  final int initialClass;
  final int classCount;

  const GradeAndClassPickerDialog({
    Key? key,
    required this.initialGrade,
    required this.initialClass,
    required this.classCount,
  }) : super(key: key);

  @override
  State<GradeAndClassPickerDialog> createState() =>
      _GradeAndClassPickerDialogState();
}

class _GradeAndClassPickerDialogState extends State<GradeAndClassPickerDialog> {
  late int selectedGrade;
  late int selectedClass;

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.initialGrade;
    selectedClass = widget.initialClass;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('학년'),
              NumberPicker(
                minValue: 1,
                maxValue: 3,
                value: selectedGrade,
                onChanged: (value) {
                  setState(() {
                    selectedGrade = value;
                  });
                },
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('반'),
              NumberPicker(
                minValue: 1,
                maxValue: widget.classCount,
                value: selectedClass,
                onChanged: (value) {
                  setState(() {
                    selectedClass = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop([selectedGrade, selectedClass]);
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
