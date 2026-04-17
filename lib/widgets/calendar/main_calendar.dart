import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

class MainCalendar extends StatefulWidget {
  final void Function(DateTime, DateTime) onDaySelected;
  final DateTime selectedDate;
  final Map<String, List<int>>? personalEvents;
  final List<PersonalEventBar>? personalBars;

  const MainCalendar({
    super.key,
    required this.onDaySelected,
    required this.selectedDate,
    this.personalEvents,
    this.personalBars,
  });

  @override
  State<MainCalendar> createState() => _MainCalendarState();
}

class _MainCalendarState extends State<MainCalendar> {
  static final _firstDay = DateTime.utc(1800, 1, 1);
  static final _lastDay = DateTime.utc(3000, 1, 1);

  late PageController _pageController;
  late int _currentIndex;
  late DateTime _focusedDay;

  final NoticeDataApi _noticeApi = NoticeDataApi();
  Map<String, String> _monthEvents = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
    _currentIndex = _monthDiff(_firstDay, _focusedDay);
    _pageController = PageController(initialPage: _currentIndex);
    _loadMonthEvents(_focusedDay);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _monthDiff(DateTime a, DateTime b) => (b.year - a.year) * 12 + b.month - a.month;

  DateTime _monthFromIndex(int index) => DateTime.utc(_firstDay.year, _firstDay.month + index);

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonthEvents(DateTime month) async {
    final events = await _noticeApi.getMonthEvents(month);
    final mapped = <String, String>{};
    events.forEach((k, v) => mapped[_dayKey(k)] = v);
    if (mounted) setState(() => _monthEvents = mapped);
  }

  List<DateTime> _visibleDays(DateTime month) {
    final first = DateTime.utc(month.year, month.month, 1);
    final before = first.weekday % 7;
    final start = first.subtract(Duration(days: before));
    final last = DateTime.utc(month.year, month.month + 1, 0);
    final after = (7 - (last.weekday + 1) % 7) % 7;
    final end = last.add(Duration(days: after));
    final count = end.difference(start).inDays + 1;
    return List.generate(count, (i) => DateTime.utc(start.year, start.month, start.day + i));
  }

  List<_Bar> _buildBars(List<DateTime> days) {
    final bars = <_Bar>[];
    String? cur;
    int si = -1;
    for (int i = 0; i < days.length; i++) {
      final n = _monthEvents[_dayKey(days[i])];
      if (n != null && n == cur) continue;
      if (cur != null && si >= 0 && si != i - 1) _splitBars(bars, cur, si, i - 1);
      if (n != null) { cur = n; si = i; } else { cur = null; si = -1; }
    }
    if (cur != null && si >= 0 && si != days.length - 1) _splitBars(bars, cur, si, days.length - 1);

    return bars;
  }

  void _splitBars(List<_Bar> bars, String name, int s, int e) {
    int i = s;
    while (i <= e) {
      final row = i ~/ 7;
      final re = ((row + 1) * 7 - 1).clamp(0, e);
      bars.add(_Bar(name: name, row: row, sc: i % 7, ec: re % 7, isS: i == s, isE: re == e));
      i = re + 1;
    }
  }

  bool _isToday(DateTime d) { final n = DateTime.now(); return d.year == n.year && d.month == n.month && d.day == n.day; }
  bool _isSelected(DateTime d) => d.year == widget.selectedDate.year && d.month == widget.selectedDate.month && d.day == widget.selectedDate.day;
  bool _isCurMonth(DateTime d, DateTime m) => d.month == m.month && d.year == m.year;
  bool _isSingle(DateTime d) {
    final k = _dayKey(d); if (!_monthEvents.containsKey(k)) return false;
    final n = _monthEvents[k]!;
    return _monthEvents[_dayKey(d.subtract(const Duration(days: 1)))] != n && _monthEvents[_dayKey(d.add(const Duration(days: 1)))] != n;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1E1E1E);
    final subColor = isDark ? const Color(0xFF8B8F99) : const Color(0xFF999999);
    final l10n = AppLocalizations.of(context)!;
    final weekdays = [l10n.calendar_weekdaySun, l10n.calendar_weekdayMon, l10n.calendar_weekdayTue, l10n.calendar_weekdayWed, l10n.calendar_weekdayThu, l10n.calendar_weekdayFri, l10n.calendar_weekdaySat];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  button: true,
                  label: 'Previous month',
                  child: GestureDetector(
                    onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                    child: Icon(Icons.chevron_left, color: textColor, size: 22),
                  ),
                ),
                const SizedBox(width: 16),
                Text(DateFormat(AppLocalizations.of(context)!.common_dateYM, Localizations.localeOf(context).toString()).format(_focusedDay),
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(width: 16),
                Semantics(
                  button: true,
                  label: 'Next month',
                  child: GestureDetector(
                    onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
                    child: Icon(Icons.chevron_right, color: textColor, size: 22),
                  ),
                ),
              ],
            ),
          ),
          Table(
            children: [
              TableRow(
                children: weekdays.map((d) => SizedBox(
                  height: 32,
                  child: Center(child: Text(d, style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600))),
                )).toList(),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final totalPages = _monthDiff(_firstDay, _lastDay) + 1;

              return AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: SizedBox(
                  height: (_visibleDays(_monthFromIndex(_currentIndex)).length ~/ 7) * 54.0,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: totalPages,
                    onPageChanged: (index) {
                      final month = _monthFromIndex(index);
                      setState(() { _currentIndex = index; _focusedDay = month; });
                      _loadMonthEvents(month);
                    },
                    itemBuilder: (context, index) {
                      final month = _monthFromIndex(index);
                      final days = _visibleDays(month);
                      final rowCount = days.length ~/ 7;
                      final bars = _buildBars(days);
                      final pBars = _buildPersonalBars(days);
                      final cellW = constraints.maxWidth / 7;
                      const cellH = 54.0;
                      const barH = 14.0;
                      const barTop = 38.0;
                      const eventColor = Color(0xFF4CAF50);

                      return Stack(
                        children: [
                          Table(
                            children: List.generate(rowCount, (row) => TableRow(
                              children: List.generate(7, (col) {
                                final day = days[row * 7 + col];
                                final cur = _isCurMonth(day, month);
                                final today = _isToday(day);
                                final sel = _isSelected(day);
                                final single = _isSingle(day);
                                final key = _dayKey(day);

                                Color dc = textColor;
                                if (!cur) {
                                  dc = textColor.withAlpha(80);
                                } else if (day.weekday == DateTime.saturday) {
                                  dc = const Color(0xFF5B8DEF);
                                } else if (day.weekday == DateTime.sunday) {
                                  dc = const Color(0xFFEF5B5B);
                                }

                                return GestureDetector(
                                  onTap: () {
                                    widget.onDaySelected(day, day);
                                    setState(() => _focusedDay = day);
                                  },
                                  child: SizedBox(
                                    height: cellH,
                                    child: Stack(
                                      alignment: Alignment.topCenter,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Container(
                                            width: 34, height: 34,
                                            decoration: (today || sel) ? BoxDecoration(
                                              color: sel ? AppColors.theme.primaryColor : AppColors.theme.primaryColor.withAlpha(40),
                                              shape: BoxShape.circle,
                                            ) : null,
                                            child: Center(child: Text(day.day.toString(), style: TextStyle(
                                              color: sel ? Colors.white : (today ? AppColors.theme.primaryColor : dc),
                                              fontSize: 14, fontWeight: (today || sel) ? FontWeight.w700 : FontWeight.normal,
                                            ))),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 2,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (single) Container(width: 5, height: 5, decoration: const BoxDecoration(color: eventColor, shape: BoxShape.circle)),
                                              if (widget.personalEvents != null && widget.personalEvents!.containsKey(key))
                                                ...widget.personalEvents![key]!.take(3).map((c) => Padding(
                                                  padding: const EdgeInsets.only(left: 2),
                                                  child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle)),
                                                )),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            )),
                          ),
                          IgnorePointer(child: Stack(children: [
                          ...bars.map((b) => Positioned(
                            top: b.row * cellH + barTop,
                            left: b.sc * cellW + (b.isS ? 3 : 0),
                            width: (b.ec - b.sc + 1) * cellW - (b.isS ? 3 : 0) - (b.isE ? 3 : 0),
                            height: barH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: eventColor.withAlpha(45),
                                borderRadius: BorderRadius.horizontal(
                                  left: b.isS ? const Radius.circular(4) : Radius.zero,
                                  right: b.isE ? const Radius.circular(4) : Radius.zero,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 4),
                              child: b.isS ? Text(b.name, style: const TextStyle(fontSize: 9, color: eventColor, fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis, maxLines: 1) : null,
                            ),
                          )),
                          ...pBars.map((b) => Positioned(
                            top: b.row * cellH + barTop,
                            left: b.sc * cellW + (b.isS ? 3 : 0),
                            width: (b.ec - b.sc + 1) * cellW - (b.isS ? 3 : 0) - (b.isE ? 3 : 0),
                            height: barH,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(b.color).withAlpha(50),
                                borderRadius: BorderRadius.horizontal(
                                  left: b.isS ? const Radius.circular(4) : Radius.zero,
                                  right: b.isE ? const Radius.circular(4) : Radius.zero,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 4),
                              child: b.isS ? Text(b.name, style: TextStyle(fontSize: 9, color: Color(b.color), fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis, maxLines: 1) : null,
                            ),
                          )),
                          ])),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<_PBar> _buildPersonalBars(List<DateTime> days) {
    if (widget.personalBars == null || widget.personalBars!.isEmpty) return [];
    final result = <_PBar>[];
    for (final pb in widget.personalBars!) {
      int si = -1, ei = -1;
      for (int i = 0; i < days.length; i++) {
        final dk = _dayKey(days[i]);
        if (dk == pb.startDate) si = i;
        if (dk == pb.endDate) ei = i;
      }
      if (si < 0 || ei < 0 || si == ei) continue;
      int i = si;
      while (i <= ei) {
        final row = i ~/ 7;
        final re = ((row + 1) * 7 - 1).clamp(0, ei);
        result.add(_PBar(name: pb.name, row: row, sc: i % 7, ec: re % 7, isS: i == si, isE: re == ei, color: pb.color));
        i = re + 1;
      }
    }
    return result;
  }
}

class _Bar {
  final String name;
  final int row, sc, ec;
  final bool isS, isE;
  _Bar({required this.name, required this.row, required this.sc, required this.ec, required this.isS, required this.isE});
}

class _PBar {
  final String name;
  final int row, sc, ec, color;
  final bool isS, isE;
  _PBar({required this.name, required this.row, required this.sc, required this.ec, required this.isS, required this.isE, required this.color});
}

class PersonalEventBar {
  final String name;
  final String startDate;
  final String endDate;
  final int color;
  PersonalEventBar({required this.name, required this.startDate, required this.endDate, required this.color});
}
