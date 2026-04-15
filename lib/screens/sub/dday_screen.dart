import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';
import 'package:hansol_high_school/data/dday_manager.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

class DDayScreen extends StatefulWidget {
  const DDayScreen({Key? key}) : super(key: key);

  @override
  State<DDayScreen> createState() => _DDayScreenState();
}

class _DDayScreenState extends State<DDayScreen> {
  List<DDay> _list = [];
  List<_EventItem> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final items = <_EventItem>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final schedules = await GetIt.I<LocalDataBase>().getSchedulesForDateRange(now, 30);
    for (var s in schedules) {
      final d = DateTime.parse(s.date);
      items.add(_EventItem(
        title: s.content,
        date: d,
        dDay: d.difference(today).inDays,
        type: _EventType.personal,
      ));
    }

    final api = NoticeDataApi();
    final schoolEvents = await api.getEventsInRange(days: 180);
    String? prevName;
    for (var event in schoolEvents) {
      if (event.name == prevName) continue;
      prevName = event.name;
      items.add(_EventItem(
        title: event.name,
        date: event.date,
        dDay: event.dDay,
        type: _EventType.school,
      ));
    }

    items.sort((a, b) => a.date.compareTo(b.date));
    if (mounted) setState(() => _events = items);
  }

  Future<void> _load() async {
    _list = await DDayManager.loadAll();
    _list.sort((a, b) => a.date.compareTo(b.date));
    setState(() {});
  }

  Future<void> _save() async {
    await DDayManager.saveAll(_list);
  }

  Future<void> _addDDay() async {
    final titleController = TextEditingController();
    DateTime? selectedDate;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context)!.dday_addTitle, style: TextStyle(
                    fontSize: Responsive.sp(context, 18), fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.dday_hint,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        locale: const Locale('ko', 'KR'),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        selectedDate != null
                            ? DateFormat(AppLocalizations.of(context)!.common_dateYmd, Localizations.localeOf(context).toString()).format(selectedDate!)
                            : AppLocalizations.of(context)!.dday_selectDate,
                        style: TextStyle(
                          color: selectedDate != null
                              ? Theme.of(ctx).textTheme.bodyLarge?.color
                              : AppColors.theme.darkGreyColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.trim().isEmpty || selectedDate == null) return;
                            Navigator.pop(ctx, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(AppLocalizations.of(context)!.dday_addButton),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty && selectedDate != null) {
      _list.add(DDay(title: titleController.text.trim(), date: selectedDate!, isPinned: _list.isEmpty));
      _list.sort((a, b) => a.date.compareTo(b.date));
      await _save();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(AppLocalizations.of(context)!.dday_screenTitle),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDDay,
        backgroundColor: AppColors.theme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: (_list.isEmpty && _events.isEmpty)
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event, size: Responsive.r(context, 48), color: AppColors.theme.darkGreyColor),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)!.dday_empty, style: TextStyle(color: AppColors.theme.darkGreyColor)),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 80),
              itemCount: _list.length + (_events.isNotEmpty ? 1 + _events.length : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index >= _list.length) {
                  final eventIndex = index - _list.length;
                  if (eventIndex == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 4),
                      child: Text(AppLocalizations.of(context)!.dday_upcoming, style: TextStyle(
                        fontSize: Responsive.sp(context, 14), fontWeight: FontWeight.w600,
                        color: AppColors.theme.darkGreyColor)),
                    );
                  }
                  final event = _events[eventIndex - 1];
                  final isSchool = event.type == _EventType.school;
                  final accentColor = isSchool ? AppColors.theme.secondaryColor : AppColors.theme.tertiaryColor;
                  final alreadyAdded = _list.any((d) => d.title == event.title &&
                      d.date.year == event.date.year && d.date.month == event.date.month && d.date.day == event.date.day);
                  return GestureDetector(
                    onTap: alreadyAdded ? null : () async {
                      _list.add(DDay(title: event.title, date: event.date, isPinned: _list.isEmpty));
                      _list.sort((a, b) => a.date.compareTo(b.date));
                      await _save();
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.dday_added(event.title))),
                      );
                    },
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2028) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: Responsive.r(context, 44), height: Responsive.r(context, 44),
                          decoration: BoxDecoration(
                            color: accentColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text(
                            event.dDay == 0 ? AppLocalizations.of(context)!.dday_today : AppLocalizations.of(context)!.dday_daysPrefix(event.dDay),
                            style: TextStyle(fontSize: Responsive.sp(context, 12), fontWeight: FontWeight.w700, color: accentColor),
                          )),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title, style: TextStyle(
                              fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w500, color: textColor)),
                            Row(
                              children: [
                                Text(DateFormat(AppLocalizations.of(context)!.common_dateMdE, Localizations.localeOf(context).toString()).format(event.date),
                                  style: TextStyle(fontSize: Responsive.sp(context, 12), color: AppColors.theme.mealTypeTextColor)),
                                if (isSchool) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: accentColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(AppLocalizations.of(context)!.dday_school, style: TextStyle(fontSize: Responsive.sp(context, 10), color: accentColor)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        )),
                        if (alreadyAdded)
                          Icon(Icons.check, size: Responsive.r(context, 18), color: AppColors.theme.primaryColor)
                        else
                          Icon(Icons.add_circle_outline, size: Responsive.r(context, 18), color: AppColors.theme.darkGreyColor),
                      ],
                    ),
                  ),
                  );
                }

                final dday = _list[index];
                final days = dday.dDay;
                final isPast = days < 0;

                return Dismissible(
                  key: ValueKey('${dday.title}_${dday.date}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    _list.removeAt(index);
                    _save();
                    setState(() {});
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        for (int i = 0; i < _list.length; i++) {
                          _list[i] = DDay(
                            title: _list[i].title,
                            date: _list[i].date,
                            isPinned: i == index,
                          );
                        }
                      });
                      _save();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2028) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: dday.isPinned
                            ? Border.all(color: AppColors.theme.primaryColor, width: 1.5)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: Responsive.r(context, 56), height: Responsive.r(context, 56),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? AppColors.theme.darkGreyColor.withAlpha(30)
                                  : AppColors.theme.primaryColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                isPast ? AppLocalizations.of(context)!.dday_daysPastPrefix(-days) : days == 0 ? AppLocalizations.of(context)!.dday_dday : AppLocalizations.of(context)!.dday_daysPrefix(days),
                                style: TextStyle(
                                  fontSize: Responsive.sp(context, days.abs() > 99 ? 12 : 16),
                                  fontWeight: FontWeight.w800,
                                  color: isPast ? AppColors.theme.darkGreyColor : AppColors.theme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dday.title, style: TextStyle(
                                  fontSize: Responsive.sp(context, 16), fontWeight: FontWeight.w600, color: textColor)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(AppLocalizations.of(context)!.common_dateYMdE, Localizations.localeOf(context).toString()).format(dday.date),
                                  style: TextStyle(fontSize: Responsive.sp(context, 13), color: AppColors.theme.mealTypeTextColor),
                                ),
                              ],
                            ),
                          ),
                          if (dday.isPinned)
                            Icon(Icons.push_pin, size: Responsive.r(context, 18), color: AppColors.theme.primaryColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

enum _EventType { personal, school }

class _EventItem {
  final String title;
  final DateTime date;
  final int dDay;
  final _EventType type;

  _EventItem({
    required this.title,
    required this.date,
    required this.dDay,
    required this.type,
  });
}
