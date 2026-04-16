import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hansol_high_school/data/api_strings.dart';
import 'package:hansol_high_school/data/exceptions.dart';
import 'nies_api_keys.dart';

class UpcomingEvent {
  final String name;
  final DateTime date;
  final int dDay;

  UpcomingEvent({required this.name, required this.date, required this.dDay});
}

class NoticeDataApi {
  static const _tag = 'NoticeDataApi';

  static http.Client _client = http.Client();

  @visibleForTesting
  static set client(http.Client c) => _client = c;

  @visibleForTesting
  static void resetClient() => _client = http.Client();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> getNotice({required DateTime date}) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final cacheKey = 'notice_$formattedDate';
    final prefs = await _prefs;

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const halfDay = 12 * 60 * 60 * 1000;
      const maxStale = 2 * 24 * 60 * 60 * 1000; // SWR: 2일까지 stale 허용

      final age = currentTime - cachedTimestamp;
      if (age < halfDay) {
        return prefs.getString(cacheKey);
      } else if (age < maxStale) {
        // SWR: stale 캐시 즉시 반환
        log('$_tag: getNotice stale cache for $cacheKey');
        return prefs.getString(cacheKey);
      } else {
        prefs.remove(cacheKey);
        prefs.remove('$cacheKey-timestamp');
      }
    }

    if (await NetworkStatus.isUnconnected()) {
      return ApiStrings.noticeNoInternet;
    }

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?key=${NiesApiKeys.niesApiKey}'
        '&Type=json&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
        '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
        '&AA_YMD=$formattedDate';

    late final Map<String, dynamic> data;
    try {
      data = await _fetchData(requestURL);
    } on NetworkException {
      _cache(prefs, cacheKey, ApiStrings.noticeNoData);
      return ApiStrings.noticeNoData;
    }

    if (data.containsKey('RESULT') && data['RESULT']['CODE'] == 'INFO-200') {
      _cache(prefs, cacheKey, ApiStrings.noticeNoData);
      return ApiStrings.noticeNoData;
    }

    if (!data.containsKey('SchoolSchedule')) {
      _cache(prefs, cacheKey, ApiStrings.noticeNoData);
      return ApiStrings.noticeNoData;
    }

    final notice = _processSchoolSchedule(data['SchoolSchedule']);
    _cache(prefs, cacheKey, notice ?? ApiStrings.noticeNoData);
    return notice;
  }

  Future<UpcomingEvent?> getUpcomingEvent() async {
    final prefs = await _prefs;
    const cacheKey = 'upcoming_event';
    final now = DateTime.now();

    if (prefs.containsKey(cacheKey)) {
      final ts = prefs.getInt('$cacheKey-timestamp') ?? 0;
      if (now.millisecondsSinceEpoch - ts < 6 * 60 * 60 * 1000) {
        final cached = prefs.getString(cacheKey);
        if (cached != null) {
          final json = jsonDecode(cached);
          final eventDate = DateTime.parse(json['date']);
          final dDay = eventDate.difference(DateTime(now.year, now.month, now.day)).inDays;
          if (dDay >= 0) {
            return UpcomingEvent(
              name: json['name'],
              date: eventDate,
              dDay: dDay,
            );
          }
        }
      }
    }

    if (await NetworkStatus.isUnconnected()) return null;

    final tomorrow = now.add(const Duration(days: 1));
    final endDate = now.add(const Duration(days: 90));
    final fromDate = DateFormat('yyyyMMdd').format(tomorrow);
    final toDate = DateFormat('yyyyMMdd').format(endDate);

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?key=${NiesApiKeys.niesApiKey}'
        '&Type=json&pIndex=1&pSize=100'
        '&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
        '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
        '&AA_FROM_YMD=$fromDate'
        '&AA_TO_YMD=$toDate';

    log('$_tag: getUpcomingEvent: $requestURL');

    late final Map<String, dynamic> data;
    try {
      data = await _fetchData(requestURL);
    } on NetworkException {
      return null;
    }

    if (data.containsKey('RESULT') && data['RESULT']['CODE'] == 'INFO-200') {
      return null;
    }

    if (!data.containsKey('SchoolSchedule')) return null;

    final events = <UpcomingEvent>[];
    final infoArray = data['SchoolSchedule'] as List<dynamic>;

    for (var info in infoArray) {
      if (!info.containsKey('row')) continue;
      for (var row in info['row']) {
        if (!row.containsKey('EVENT_NM')) continue;
        final eventName = row['EVENT_NM'] as String;
        if (eventName == '토요휴업일') continue;

        final dateStr = row['AA_YMD'] as String;
        final eventDate = DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
        final dDay = eventDate
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;

        if (dDay > 0) {
          events.add(UpcomingEvent(
            name: eventName,
            date: eventDate,
            dDay: dDay,
          ));
        }
      }
    }

    if (events.isEmpty) return null;

    events.sort((a, b) => a.dDay.compareTo(b.dDay));
    final nearest = events.first;

    prefs.setString(cacheKey, jsonEncode({
      'name': nearest.name,
      'date': nearest.date.toIso8601String(),
    }));
    prefs.setInt('$cacheKey-timestamp', now.millisecondsSinceEpoch);

    return nearest;
  }

  Future<List<UpcomingEvent>> getEventsInRange({int days = 30}) async {
    if (await NetworkStatus.isUnconnected()) return [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDate = now.add(Duration(days: days));
    final fromDate = DateFormat('yyyyMMdd').format(now);
    final toDate = DateFormat('yyyyMMdd').format(endDate);

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?key=${NiesApiKeys.niesApiKey}'
        '&Type=json&pIndex=1&pSize=100'
        '&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
        '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
        '&AA_FROM_YMD=$fromDate'
        '&AA_TO_YMD=$toDate';

    late final Map<String, dynamic> data;
    try {
      data = await _fetchData(requestURL);
    } on NetworkException {
      return [];
    }
    if (data.containsKey('RESULT') && data['RESULT']['CODE'] == 'INFO-200') return [];
    if (!data.containsKey('SchoolSchedule')) return [];

    final events = <UpcomingEvent>[];
    final infoArray = data['SchoolSchedule'] as List<dynamic>;

    for (var info in infoArray) {
      if (!info.containsKey('row')) continue;
      for (var row in info['row']) {
        if (!row.containsKey('EVENT_NM')) continue;
        final eventName = row['EVENT_NM'] as String;
        if (eventName == '토요휴업일') continue;

        final dateStr = row['AA_YMD'] as String;
        final eventDate = DateTime(
          int.parse(dateStr.substring(0, 4)),
          int.parse(dateStr.substring(4, 6)),
          int.parse(dateStr.substring(6, 8)),
        );
        final dDay = eventDate.difference(today).inDays;

        if (dDay >= 0) {
          events.add(UpcomingEvent(
            name: eventName,
            date: eventDate,
            dDay: dDay,
          ));
        }
      }
    }

    events.sort((a, b) => a.dDay.compareTo(b.dDay));
    return events;
  }

  Future<Map<DateTime, String>> getMonthEvents(DateTime month) async {
    final prefs = await _prefs;
    final monthKey = DateFormat('yyyyMM').format(month);
    final cacheKey = 'month_events_v2_$monthKey';

    if (prefs.containsKey(cacheKey)) {
      final ts = prefs.getInt('$cacheKey-timestamp') ?? 0;
      if (DateTime.now().millisecondsSinceEpoch - ts < 12 * 60 * 60 * 1000) {
        final cached = jsonDecode(prefs.getString(cacheKey)!) as Map<String, dynamic>;
        return cached.map((k, v) => MapEntry(DateTime.parse(k), v as String));
      }
    }

    if (await NetworkStatus.isUnconnected()) return {};

    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final fromDate = DateFormat('yyyyMMdd').format(firstDay);
    final toDate = DateFormat('yyyyMMdd').format(lastDay);

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?key=${NiesApiKeys.niesApiKey}'
        '&Type=json&pIndex=1&pSize=100'
        '&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
        '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
        '&AA_FROM_YMD=$fromDate'
        '&AA_TO_YMD=$toDate';

    late final Map<String, dynamic> data;
    try {
      data = await _fetchData(requestURL);
    } on NetworkException {
      return {};
    }
    final result = <DateTime, String>{};

    if (data.containsKey('SchoolSchedule')) {
      final infoArray = data['SchoolSchedule'] as List<dynamic>;
      for (var info in infoArray) {
        if (!info.containsKey('row')) continue;
        for (var row in info['row']) {
          if (!row.containsKey('EVENT_NM')) continue;
          final name = row['EVENT_NM'] as String;
          if (name == '토요휴업일') continue;
          final dateStr = row['AA_YMD'] as String;
          final date = DateTime(
            int.parse(dateStr.substring(0, 4)),
            int.parse(dateStr.substring(4, 6)),
            int.parse(dateStr.substring(6, 8)),
          );
          result[date] = name;
        }
      }
    }

    final cacheMap = result.map((k, v) => MapEntry(k.toIso8601String(), v));
    prefs.setString(cacheKey, jsonEncode(cacheMap));
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);

    return result;
  }

  void _cache(SharedPreferences prefs, String cacheKey, String value) {
    prefs.setString(cacheKey, value);
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> _fetchData(String url) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw NetworkException('HTTP ${response.statusCode}');
      }
      return jsonDecode(response.body);
    } on NetworkException {
      rethrow;
    } on TimeoutException catch (e) {
      log('$_tag: fetch timeout');
      throw NetworkException('요청 시간 초과', e);
    } catch (e) {
      log('$_tag: fetch error: $e');
      throw NetworkException('API 요청 실패', e);
    }
  }

  String? _processSchoolSchedule(List<dynamic> schoolScheduleArray) {
    for (var schedule in schoolScheduleArray) {
      if (!schedule.containsKey('row')) continue;
      for (var row in schedule['row']) {
        if (!row.containsKey('EVENT_NM')) continue;
        if (row['EVENT_NM'] == '토요휴업일') return null;
        return row['EVENT_NM'];
      }
    }
    return null;
  }
}
