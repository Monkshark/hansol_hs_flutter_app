import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

class EventAttachCard extends StatelessWidget {
  final DateTime eventDate;
  final String eventContent;
  final int startTime;
  final int endTime;
  final VoidCallback onAdd;

  const EventAttachCard({
    super.key,
    required this.eventDate,
    required this.eventContent,
    required this.startTime,
    required this.endTime,
    required this.onAdd,
  });

  String _formatTime(int minutes, {required String am, required String pm}) {
    if (minutes < 0) return '';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final period = h < 12 ? am : pm;
    final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$period $hour:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final hasTime = startTime >= 0 && endTime >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.tertiaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, size: 18, color: AppColors.theme.tertiaryColor),
              const SizedBox(width: 6),
              Text(l10n.event_cardTitle, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.theme.tertiaryColor)),
            ],
          ),
          const SizedBox(height: 10),
          Text(eventContent, style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text(
            DateFormat(AppLocalizations.of(context)!.common_dateYmdE, Localizations.localeOf(context).toString()).format(eventDate) +
                (hasTime ? '  ${_formatTime(startTime, am: l10n.event_am, pm: l10n.event_pm)} - ${_formatTime(endTime, am: l10n.event_am, pm: l10n.event_pm)}' : ''),
            style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.event_cardAddButton),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.theme.tertiaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
