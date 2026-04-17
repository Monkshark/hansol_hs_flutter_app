import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/providers/home_provider.dart';
import 'package:hansol_high_school/screens/sub/dday_screen.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:intl/intl.dart';

class UpcomingEventDDay extends ConsumerWidget {
  final VoidCallback onRefresh;
  const UpcomingEventDDay({required this.onRefresh, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDDay = ref.watch(pinnedDDayProvider);

    return asyncDDay.when(
      loading: () => Text(
        AppLocalizations.of(context)!.home_scheduleLoading,
        style: TextStyle(color: Colors.white, fontSize: Responsive.sp(context, 22), fontWeight: FontWeight.w700),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (pinnedDDay) {
        if (pinnedDDay == null) {
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DDayScreen()),
            ).then((_) => onRefresh()),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white.withAlpha(200), size: Responsive.r(context, 20)),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.home_ddaySet,
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final d = pinnedDDay.dDay;
        final dDayText = d == 0 ? 'D-Day' : d > 0 ? 'D-$d' : 'D+${-d}';
        final titleText = '${pinnedDDay.title} · ${DateFormat('M/d', Localizations.localeOf(context).toString()).format(pinnedDDay.date)}';

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DDayScreen()),
          ).then((_) => onRefresh()),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                dDayText,
                style: TextStyle(
                  color: Colors.white, fontSize: Responsive.sp(context, 28),
                  fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  titleText,
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TodayLunchPreview extends ConsumerWidget {
  const TodayLunchPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMeal = ref.watch(todayLunchProvider);

    String preview = AppLocalizations.of(context)!.home_lunchPreview;
    asyncMeal.whenData((meal) {
      if (meal?.meal != null) {
        final items = meal!.meal!.split('\n').take(3).map((e) =>
          e.replaceAll(RegExp(r'\([0-9.,\s]+\)'), '').trim()
        ).where((e) => e.isNotEmpty).join(' · ');
        preview = '🍱 $items';
      } else {
        preview = AppLocalizations.of(context)!.home_lunchNoInfo;
      }
    });

    return Text(
      preview,
      style: TextStyle(
        color: Colors.white.withAlpha(180),
        fontSize: Responsive.sp(context, 12),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
