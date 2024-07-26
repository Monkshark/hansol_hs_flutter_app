import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/Widgets/CalendarWidgets/custom_text_field.dart';
import 'package:hansol_high_school/styles.dart';
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

    Future<void> pickTime(BuildContext context, bool isStart) async {
      final now = TimeOfDay.now();
      final initialTime = TimeOfDay(hour: now.hour, minute: 0);

      if (Platform.isIOS) {
        showCupertinoModalPopup(
          context: context,
          builder: (context) {
            return Container(
              height: 250,
              color: Colors.white,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  widget.selectedDate.year,
                  widget.selectedDate.month,
                  widget.selectedDate.day,
                  initialTime.hour,
                  initialTime.minute,
                ),
                use24hFormat: false,
                onDateTimeChanged: (DateTime newDateTime) {
                  setState(() {
                    if (isStart) {
                      startTime = newDateTime.hour;
                    } else {
                      endTime = newDateTime.hour;
                    }
                  });
                },
              ),
            );
          },
        );
      } else {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) {
            return MediaQuery(
              data:
                  MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          int hour24Format;
          hour24Format = pickedTime.hour == 12 ? 12 : pickedTime.hour + 0;

          setState(() {
            if (isStart) {
              startTime = hour24Format;
            } else {
              endTime = hour24Format;
            }
          });
        }
      }
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
                const Text(
                  '일정 만들기',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => pickTime(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              startTime == null
                                  ? '시작 시간'
                                  : '${startTime! < 10 ? '0$startTime' : startTime}:00',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => pickTime(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              endTime == null
                                  ? '종료 시간'
                                  : '${endTime! < 10 ? '0$endTime' : endTime}:00',
                              style: const TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ),
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
                    validator: (String? val) {
                      if (val == null || val.isEmpty) return "값을 입력해주세요";
                      return null;
                    },
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
                const SizedBox(height: 16.0)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
