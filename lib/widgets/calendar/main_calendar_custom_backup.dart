import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

class MainCalendar extends StatefulWidget {
  final void Function(DateTime, DateTime) onDaySelected;
  final DateTime selectedDate;
  final Map<String, List<int>>? personalEvents;

  const MainCalendar({
    Key? key,
    required this.onDaySelected,
    required this.selectedDate,
    this.personalEvents,
  }) : super(key: key);

  @override
  State<MainCalendar> createState() => _MainCalendarState();
}

class _MainCalendarState extends State<MainCalendar> {
  late DateTime _focusedMonth;
  late DateTime _baseMonth;
  late PageController _pageController;
  static const _initialPage = 1200;
  final NoticeDataApi _noticeApi = NoticeDataApi();
  Map<String, String> _monthEvents = {};

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _baseMonth = _focusedMonth;
    _pageController = PageController(initialPage: _initialPage);
    _loadMonthEvents(_focusedMonth);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _monthFromPage(int page) {
    final diff = page - _initialPage;
    return DateTime(_baseMonth.year, _baseMonth.month + diff);
  }

  String _dayKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  Future<void> _loadMonthEvents(DateTime month) async {
    final events = await _noticeApi.getMonthEvents(month);
    final mapped = <String, String>{};
    events.forEach((k, v) => mapped[_dayKey(k)] = v);
    if (mounted) setState(() => _monthEvents = mapped);
  }

  List<DateTime> _buildDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final startWeekday = first.weekday % 7;
    final start = first.subtract(Duration(days: startWeekday));
    final last = DateTime(month.year, month.month + 1, 0);
    final endWeekday = last.weekday % 7;
    final totalDays = startWeekday + last.day + (6 - endWeekday);
    return List.generate(totalDays, (i) => start.add(Duration(days: i)));
  }

  int _rowCount(DateTime month) {
    final days = _buildDays(month);
    return (days.length / 7).ceil();
  }

  List<_EventBar> _buildEventBars(List<DateTime> days) {
    final bars = <_EventBar>[];
    String? currentName;
    int startIdx = -1;

    for (int i = 0; i < days.length; i++) {
      final name = _monthEvents[_dayKey(days[i])];
      if (name != null && name == currentName) continue;
      if (currentName != null && startIdx >= 0) {
        _addBars(bars, currentName, startIdx, i - 1);
      }
      if (name != null) { currentName = name; startIdx = i; }
      else { currentName = null; startIdx = -1; }
    }
    if (currentName != null && startIdx >= 0) {
      _addBars(bars, currentName, startIdx, days.length - 1);
    }
    return bars;
  }

  void _addBars(List<_EventBar> bars, String name, int startIdx, int endIdx) {
    if (startIdx == endIdx) return;
    int i = startIdx;
    while (i <= endIdx) {
      final row = i ~/ 7;
      final rowEnd = (row + 1) * 7 - 1;
      final end = endIdx < rowEnd ? endIdx : rowEnd;
      bars.add(_EventBar(name: name, row: row, startCol: i % 7, endCol: end % 7, isStart: i == startIdx, isEnd: end == endIdx));
      i = end + 1;
    }
  }

  bool _isToday(DateTime d) { final n = DateTime.now(); return d.year == n.year && d.month == n.month && d.day == n.day; }
  bool _isSelected(DateTime d) => d.year == widget.selectedDate.year && d.month == widget.selectedDate.month && d.day == widget.selectedDate.day;
  bool _isCurrentMonth(DateTime d, DateTime month) => d.month == month.month && d.year == month.year;

  bool _isSingleEvent(DateTime day) {
    final key = _dayKey(day);
    if (!_monthEvents.containsKey(key)) return false;
    final name = _monthEvents[key]!;
    return _monthEvents[_dayKey(day.subtract(const Duration(days: 1)))] != name &&
        _monthEvents[_dayKey(day.add(const Duration(days: 1)))] != name;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEEEEEE) : const Color(0xFF1E1E1E);
    final subColor = isDark ? const Color(0xFF8B8F99) : const Color(0xFF999999);
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Icon(Icons.chevron_left, color: textColor, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  DateFormat(AppLocalizations.of(context)!.common_dateYM, Localizations.localeOf(context).toString()).format(_focusedMonth),
                  style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Icon(Icons.chevron_right, color: textColor, size: 22),
                ),
              ],
            ),
          ),
          Row(
            children: weekdays.map((d) => Expanded(
              child: Center(child: Text(d, style: TextStyle(color: subColor, fontSize: 13, fontWeight: FontWeight.w600))),
            )).toList(),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 6 * 48.0,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (page) {
                final month = _monthFromPage(page);
                setState(() => _focusedMonth = month);
                _loadMonthEvents(month);
              },
              itemBuilder: (context, page) {
                final month = _monthFromPage(page);
                return _buildMonthGrid(month, textColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthGrid(DateTime month, Color textColor) {
    const eventColor = Color(0xFF4CAF50);
    const cellHeight = 48.0;
    const barHeight = 14.0;
    const barTop = 32.0;
    final days = _buildDays(month);
    final rowCount = (days.length / 7).ceil();
    final eventBars = _buildEventBars(days);

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / 7;

        return SizedBox(
          height: rowCount * cellHeight,
          child: Stack(
            children: [
              ...eventBars.map((bar) => Positioned(
                top: bar.row * cellHeight + barTop,
                left: bar.startCol * cellWidth + (bar.isStart ? 3 : 0),
                width: (bar.endCol - bar.startCol + 1) * cellWidth - (bar.isStart ? 3 : 0) - (bar.isEnd ? 3 : 0),
                height: barHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: eventColor.withAlpha(45),
                    borderRadius: BorderRadius.horizontal(
                      left: bar.isStart ? const Radius.circular(4) : Radius.zero,
                      right: bar.isEnd ? const Radius.circular(4) : Radius.zero,
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 4),
                  child: bar.isStart
                      ? Text(bar.name, style: TextStyle(fontSize: 9, color: eventColor, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis, maxLines: 1)
                      : null,
                ),
              )),
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7, mainAxisExtent: cellHeight,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isCurrent = _isCurrentMonth(day, month);
                  final today = _isToday(day);
                  final selected = _isSelected(day);
                  final single = _isSingleEvent(day);

                  Color dayColor = textColor;
                  if (!isCurrent) {
                    dayColor = textColor.withAlpha(80);
                  } else if (day.weekday == DateTime.saturday) {
                    dayColor = const Color(0xFF5B8DEF);
                  } else if (day.weekday == DateTime.sunday) {
                    dayColor = const Color(0xFFEF5B5B);
                  }

                  return GestureDetector(
                    onTap: () => widget.onDaySelected(day, day),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Container(
                            width: 34, height: 34,
                            decoration: (today || selected) ? BoxDecoration(
                              color: selected ? AppColors.theme.primaryColor : AppColors.theme.primaryColor.withAlpha(40),
                              shape: BoxShape.circle,
                            ) : null,
                            child: Center(child: Text(
                              day.day.toString(),
                              style: TextStyle(
                                color: selected ? Colors.white : (today ? AppColors.theme.primaryColor : dayColor),
                                fontSize: 14,
                                fontWeight: (today || selected) ? FontWeight.w700 : FontWeight.normal,
                              ),
                            )),
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (single)
                                Container(width: 5, height: 5, decoration: BoxDecoration(color: eventColor, shape: BoxShape.circle)),
                              if (widget.personalEvents != null && widget.personalEvents!.containsKey(_dayKey(day)))
                                ...widget.personalEvents![_dayKey(day)]!.take(3).map((c) => Padding(
                                  padding: const EdgeInsets.only(left: 2),
                                  child: Container(width: 5, height: 5, decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle)),
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EventBar {
  final String name;
  final int row, startCol, endCol;
  final bool isStart, isEnd;
  _EventBar({required this.name, required this.row, required this.startCol, required this.endCol, required this.isStart, required this.isEnd});
}
