import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

class WriteEventFormSection extends StatelessWidget {
  final TextEditingController eventContentController;
  final DateTime? eventDate;
  final TimeOfDay? eventStartTime;
  final TimeOfDay? eventEndTime;
  final void Function(DateTime date) onDateChanged;
  final void Function(TimeOfDay time, bool isStart) onTimeChanged;
  final bool isDark;
  final Color? textColor;
  final Color fillColor;

  const WriteEventFormSection({
    super.key,
    required this.eventContentController,
    required this.eventDate,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.onDateChanged,
    required this.onTimeChanged,
    required this.isDark,
    required this.textColor,
    required this.fillColor,
  });

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: eventDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) onDateChanged(picked);
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initial = isStart ? (eventStartTime ?? TimeOfDay.now()) : (eventEndTime ?? TimeOfDay.now());

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 250,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime: DateTime(2024, 1, 1, initial.hour, initial.minute),
            use24hFormat: false,
            onDateTimeChanged: (dt) => onTimeChanged(TimeOfDay(hour: dt.hour, minute: dt.minute), isStart),
          ),
        ),
      );
    } else {
      final picked = await showTimePicker(context: context, initialTime: initial);
      if (picked != null) onTimeChanged(picked, isStart);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.tertiaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: eventContentController,
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.write_eventContentHint,
              hintStyle: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 14),
              filled: true,
              fillColor: fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
                  const SizedBox(width: 8),
                  Text(
                    eventDate != null
                        ? DateFormat(AppLocalizations.of(context)!.common_dateYmdE, Localizations.localeOf(context).toString()).format(eventDate!)
                        : AppLocalizations.of(context)!.write_eventSelectDate,
                    style: TextStyle(
                      fontSize: 14,
                      color: eventDate != null ? textColor : AppColors.theme.darkGreyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: AppColors.theme.darkGreyColor),
                        const SizedBox(width: 8),
                        Text(
                          eventStartTime != null ? eventStartTime!.format(context) : AppLocalizations.of(context)!.write_eventStartTimeOptional,
                          style: TextStyle(
                            fontSize: 14,
                            color: eventStartTime != null ? textColor : AppColors.theme.darkGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('~', style: TextStyle(color: AppColors.theme.darkGreyColor)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: AppColors.theme.darkGreyColor),
                        const SizedBox(width: 8),
                        Text(
                          eventEndTime != null ? eventEndTime!.format(context) : AppLocalizations.of(context)!.write_eventEndTimeOptional,
                          style: TextStyle(
                            fontSize: 14,
                            color: eventEndTime != null ? textColor : AppColors.theme.darkGreyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
