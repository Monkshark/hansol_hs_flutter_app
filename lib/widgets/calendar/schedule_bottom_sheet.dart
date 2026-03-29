import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/**
 * 일정 만들기 다이얼로그
 * - 일정 내용 텍스트 입력 필드 제공
 * - 시작/종료 시간 선택 (iOS: CupertinoPicker, Android: TimePicker)
 * - 저장 시 LocalDataBase에 Schedule 삽입 후 콜백 호출
 * - 다크/라이트 테마 대응 스타일 적용
 */
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
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('일정 만들기', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
            const SizedBox(height: 20),
            TextField(
              controller: contentController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: '일정 내용을 입력하세요',
                hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.theme.darkGreyColor),
                          const SizedBox(width: 8),
                          Text(
                            startTime != null ? startTime!.format(context) : '시작',
                            style: TextStyle(
                              color: startTime != null ? textColor : AppColors.theme.darkGreyColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('~', style: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 16)),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickTime(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: fillColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: AppColors.theme.darkGreyColor),
                          const SizedBox(width: 8),
                          Text(
                            endTime != null ? endTime!.format(context) : '종료',
                            style: TextStyle(
                              color: endTime != null ? textColor : AppColors.theme.darkGreyColor,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('추가'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (contentController.text.trim().isEmpty) return;

    final schedule = Schedule(
      startTime: startTime != null ? startTime!.hour * 60 + startTime!.minute : -1,
      endTime: endTime != null ? endTime!.hour * 60 + endTime!.minute : -1,
      content: contentController.text.trim(),
      date: widget.selectedDate.toIso8601String(),
    );

    await GetIt.I<LocalDataBase>().insertSchedule(schedule);
    Navigator.of(context).pop();
    widget.onScheduleCreated();
  }

  Future<void> _pickTime(bool isStart) async {
    final now = TimeOfDay.now();
    final initial = isStart ? (startTime ?? now) : (endTime ?? now);

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 250,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(
              widget.selectedDate.year, widget.selectedDate.month,
              widget.selectedDate.day, initial.hour, initial.minute),
            use24hFormat: false,
            onDateTimeChanged: (dt) {
              setState(() {
                if (isStart) {
                  startTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                } else {
                  endTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
                }
              });
            },
          ),
        ),
      );
    } else {
      final picked = await showTimePicker(
        context: context,
        initialTime: initial,
      );
      if (picked != null) {
        setState(() {
          if (isStart) {
            startTime = picked;
          } else {
            endTime = picked;
          }
        });
      }
    }
  }
}
