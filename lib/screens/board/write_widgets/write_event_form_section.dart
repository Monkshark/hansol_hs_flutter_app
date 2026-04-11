import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

class WriteEventFormSection extends StatelessWidget {
  final TextEditingController eventContentController;
  final DateTime? eventDate;
  final TimeOfDay? eventStartTime;
  final TimeOfDay? eventEndTime;
  final VoidCallback onPickDate;
  final void Function(bool isStart) onPickTime;
  final bool isDark;
  final Color? textColor;
  final Color fillColor;

  const WriteEventFormSection({
    super.key,
    required this.eventContentController,
    required this.eventDate,
    required this.eventStartTime,
    required this.eventEndTime,
    required this.onPickDate,
    required this.onPickTime,
    required this.isDark,
    required this.textColor,
    required this.fillColor,
  });

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
            onTap: onPickDate,
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
                  onTap: () => onPickTime(true),
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
                  onTap: () => onPickTime(false),
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
