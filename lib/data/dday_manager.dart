import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// D-day CRUD 및 SharedPreferences JSON 저장
///
/// - D-day 항목 생성/조회/수정/삭제
/// - 핀 된 D-day 조회 지원
/// - SharedPreferences에 JSON 형태로 저장
class DDay {
  final String title;
  final DateTime date;
  final bool isPinned;

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

/// D-day 목록 저장/조회 및 핀 된 D-day 관리
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
    final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
    if (pinned.isEmpty) return null;
    pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
    return pinned.first;
  }
}
