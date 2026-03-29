import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DDay {
  final String title;
  final DateTime date;
  final bool isPinned; // 홈 화면에 표시할 D-day

  DDay({required this.title, required this.date, this.isPinned = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date.toIso8601String(),
    'isPinned': isPinned,
  };

  factory DDay.fromJson(Map<String, dynamic> json) => DDay(
    title: json['title'],
    date: DateTime.parse(json['date']),
    isPinned: json['isPinned'] ?? false,
  );

  int get dDay {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(now).inDays;
  }
}

class DDayManager {
  static const _key = 'dday_list';

  static Future<List<DDay>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => DDay.fromJson(e)).toList();
  }

  static Future<void> saveAll(List<DDay> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  static Future<DDay?> getPinned() async {
    final list = await loadAll();
    // 핀 된 것 중 가장 가까운 미래 D-day
    final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
    if (pinned.isEmpty) return null;
    pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
    return pinned.first;
  }
}
