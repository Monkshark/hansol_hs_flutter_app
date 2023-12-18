import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hansol_high_school/Widgets/CustomTextField.dart';
import 'package:hansol_high_school/Widgets/MainCalendar.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onScheduleCreated;

  const ScheduleBottomSheet({
    required this.selectedDate,
    required this.onScheduleCreated,
    Key? key,
  }) : super(key: key);

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  final GlobalKey<FormState> formKey = GlobalKey();

  int? startTime;
  int? endTime;
  String? content;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    void onSavePressed() async {
      if (formKey.currentState!.validate()) {
        formKey.currentState!.save();

        final prefs = await SharedPreferences.getInstance();
        final schedules = prefs.getStringList('schedules') ?? [];

        final newSchedule = {
          'startTime': startTime,
          'endTime': endTime,
          'content': content,
          'date': widget.selectedDate.toIso8601String(),
        };

        schedules.add(jsonEncode(newSchedule));
        await prefs.setStringList('schedules', schedules);

        Navigator.of(context).pop();

        widget.onScheduleCreated();
      }
    }

    String? timeValidator(String? val) {
      if (val == null) return "값을 입력해주세요";

      int? number;

      try {
        number = int.parse(val);
      } catch (e) {
        return "숫자를 입력해주세요";
      }

      if (number < 0 || number > 24) return "0시부터 24시 사이를 입력해주세요";

      return null;
    }

    String? contextValidator(String? val) {
      if (val == null || val.isEmpty) return "값을 입력해주세요";

      return null;
    }

    return Form(
      key: formKey,
      child: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height / 2 + bottomInset,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey,
              width: 2.0,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12.0),
              topRight: Radius.circular(12.0),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 8.0,
              right: 8.0,
              top: 8.0,
              bottom: bottomInset,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: '시작 시간',
                        isTime: true,
                        onSaved: (String? val) {
                          startTime = int.parse(val!);
                        },
                        validator: timeValidator,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: CustomTextField(
                        label: '종료 시간',
                        isTime: true,
                        onSaved: (String? val) {
                          endTime = int.parse(val!);
                        },
                        validator: timeValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                Expanded(
                  child: CustomTextField(
                    label: '내용',
                    isTime: false,
                    onSaved: (String? val) {
                      content = val;
                    },
                    validator: contextValidator,
                  ),
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onSavePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PRIMARY_COLOR,
                    ),
                    child: const Text(
                      '저장',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
