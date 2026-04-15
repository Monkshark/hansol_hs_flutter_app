import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class WeeklyCalendar extends StatefulWidget {
  final Color backgroundColor;
  final Function(DateTime) onDaySelected;

  const WeeklyCalendar({
    Key? key,
    required this.backgroundColor,
    required this.onDaySelected,
  }) : super(key: key);

  @override
  State<WeeklyCalendar> createState() => _WeeklyCalendarState();
}

class _WeeklyCalendarState extends State<WeeklyCalendar> {
  DateTime _selectedDay = DateTime.now();

  static const int _initialPage = 5000;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _mondayForPage(int page) {
    final now = DateTime.now();
    final todayMonday = _mondayOf(now);
    final diff = page - _initialPage;
    return todayMonday.add(Duration(days: diff * 7));
  }

  DateTime _mondayOf(DateTime day) {
    final diff = day.weekday - DateTime.monday;
    return DateTime(day.year, day.month, day.day - diff);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _goToPreviousWeek() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToNextWeek() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final dowLabels = locale == 'ko'
        ? ['월', '화', '수', '목', '금']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    return Container(
      color: widget.backgroundColor,
      child: Column(
        children: [
          // Header: year/month
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _HeaderTitle(
                pageController: _pageController,
                initialPage: _initialPage,
                mondayForPage: _mondayForPage,
              ),
            ),
          ),
          // Arrows + swipeable (dow labels + day cells)
          Row(
            children: [
              // < 화살표
              _buildArrowButton(Icons.chevron_left, _goToPreviousWeek),
              // 요일 + 날짜 영역 전체 스와이프
              Expanded(
                child: SizedBox(
                  height: Responsive.h(context, 68),
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (page) {
                      final monday = _mondayForPage(page);
                      final inWeek = _isSameDay(_mondayOf(_selectedDay), monday);
                      if (!inWeek) {
                        setState(() => _selectedDay = monday);
                        widget.onDaySelected(monday);
                      }
                    },
                    itemBuilder: (context, page) {
                      final monday = _mondayForPage(page);
                      final weekDays = List.generate(5, (i) => monday.add(Duration(days: i)));

                      return Column(
                        children: [
                          // 요일 라벨
                          SizedBox(
                            height: Responsive.h(context, 24),
                            child: Row(
                              children: dowLabels.map((label) => Expanded(
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(160),
                                      fontSize: Responsive.sp(context, 13),
                                    ),
                                  ),
                                ),
                              )).toList(),
                            ),
                          ),
                          // 날짜 셀
                          Expanded(
                            child: Row(
                              children: weekDays.map((day) {
                                final isSelected = _isSameDay(day, _selectedDay);
                                final isToday = _isSameDay(day, DateTime.now());

                                BoxDecoration? decoration;
                                TextStyle textStyle;

                                if (isSelected) {
                                  decoration = const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  );
                                  textStyle = TextStyle(
                                    color: AppColors.theme.primaryColor,
                                    fontSize: Responsive.sp(context, 14),
                                    fontWeight: FontWeight.w700,
                                  );
                                } else if (isToday) {
                                  decoration = BoxDecoration(
                                    color: Colors.white.withAlpha(40),
                                    shape: BoxShape.circle,
                                  );
                                  textStyle = TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.sp(context, 14),
                                    fontWeight: FontWeight.w700,
                                  );
                                } else {
                                  textStyle = TextStyle(
                                    color: Colors.white,
                                    fontSize: Responsive.sp(context, 14),
                                  );
                                }

                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedDay = day);
                                      widget.onDaySelected(day);
                                    },
                                    child: Center(
                                      child: Container(
                                        width: Responsive.r(context, 36),
                                        height: Responsive.r(context, 36),
                                        decoration: decoration,
                                        alignment: Alignment.center,
                                        child: Text('${day.day}', style: textStyle),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              // > 화살표
              _buildArrowButton(Icons.chevron_right, _goToNextWeek),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildArrowButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Icon(
            icon,
            color: Colors.white.withAlpha(220),
            size: Responsive.r(context, 28),
          ),
        ),
      ),
    );
  }
}

/// 헤더 타이틀 — PageView 페이지 변경 시 년/월 자동 업데이트
class _HeaderTitle extends StatefulWidget {
  final PageController pageController;
  final int initialPage;
  final DateTime Function(int) mondayForPage;

  const _HeaderTitle({
    required this.pageController,
    required this.initialPage,
    required this.mondayForPage,
  });

  @override
  State<_HeaderTitle> createState() => _HeaderTitleState();
}

class _HeaderTitleState extends State<_HeaderTitle> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    widget.pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_onPageScroll);
    super.dispose();
  }

  void _onPageScroll() {
    final page = widget.pageController.page?.round() ?? _currentPage;
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final monday = widget.mondayForPage(_currentPage);
    return Text(
      '${monday.year}년 ${monday.month}월',
      style: TextStyle(
        color: Colors.white,
        fontSize: Responsive.sp(context, 18),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
