import 'dart:convert';
import 'dart:developer';

import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nies_api_keys.dart';

/**
 * NEIS 학사일정 API 연동
 *
 * - 날짜 범위별 학사일정 조회
 * - 예정 이벤트 조회 지원
 * - 12시간 캐시 적용
 */
class UpcomingEvent {
  final String name;
  final DateTime date;
  final int dDay;

  UpcomingEvent({required this.name, required this.date, required this.dDay});
}

class NoticeDataApi {
  static const _tag = 'NoticeDataApi';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> getNotice({required DateTime date}) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final cacheKey = 'notice_$formattedDate';
    final prefs = await _prefs;

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const halfDay = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < halfDay) {
        return prefs.getString(cacheKey);
      } else {
        prefs.remove(cacheKey);
        prefs.remove('$cacheKey-timestamp');
      }
    }

    if (await NetworkStatus.isUnconnected()) {
      return "학사일정을 확인하려면 인터넷에 연결하세요";
    }

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AA_YMD=$formattedDate';

    final data = await _fetchData(requestURL);
    if (data == null) {
      _cache(prefs, cacheKey, '학사일정이 없습니다');
      return '학사일정이 없습니다';
    }

    if (data.containsKey('RESULT') && data['RESULT']['CODE'] == 'INFO-200') {
      _cache(prefs, cacheKey, '학사일정이 없습니다');
      return '학사일정이 없습니다';
    }

    if (!data.containsKey('SchoolSchedule')) {
      _cache(prefs, cacheKey, '학사일정이 없습니다');
      return '학사일정이 없습니다';
    }

    final notice = _processSchoolSchedule(data['SchoolSchedule']);
    _cache(prefs, cacheKey, notice ?? '학사일정이 없습니다');
    return notice;
  }

  Future<UpcomingEvent?> getUpcomingEvent() async {
    final prefs = await _prefs;
    final cacheKey = 'upcoming_event';
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

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?'
        '&Type=json&pIndex=1&pSize=100'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AA_FROM_YMD=$fromDate'
        '&AA_TO_YMD=$toDate';

    log('$_tag: getUpcomingEvent: $requestURL');

    final data = await _fetchData(requestURL);
    if (data == null) return null;

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

    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?'
        '&Type=json&pIndex=1&pSize=100'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AA_FROM_YMD=$fromDate'
        '&AA_TO_YMD=$toDate';

    final data = await _fetchData(requestURL);
    if (data == null) return [];
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

  void _cache(SharedPreferences prefs, String cacheKey, String value) {
    prefs.setString(cacheKey, value);
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>?> _fetchData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      return jsonDecode(response.body);
    } catch (e) {
      log('$_tag: fetch error: $e');
      return null;
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
