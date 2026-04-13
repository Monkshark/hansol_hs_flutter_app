import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'board_search_history';
  static const _maxEntries = 10;

  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (e) {
      log('SearchHistoryService: decode error: $e');
    }
    return [];
  }

  static Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((e) => e == trimmed);
    current.insert(0, trimmed);
    final capped = current.take(_maxEntries).toList();
    await prefs.setString(_key, jsonEncode(capped));
  }

  static Future<void> remove(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await load();
    current.removeWhere((e) => e == query);
    await prefs.setString(_key, jsonEncode(current));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
