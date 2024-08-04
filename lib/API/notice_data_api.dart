import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:hansol_high_school/Network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'nies_api_keys.dart';

class NoticeDataApi {
  static const TAG = 'NoticeDataApi';

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<String?> getNotice({
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final cacheKey = formattedDate;
    final prefs = await _prefs;

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneDayInMilliseconds = 12 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < oneDayInMilliseconds) {
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

    log('$TAG: getNotice: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) {
      prefs.setString(cacheKey, '학사일정이 없습니다');
      prefs.setInt(
          '$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
      return '학사일정이 없습니다';
    }

    final notice = processSchoolSchedule(data['SchoolSchedule']);
    prefs.setString(cacheKey, notice ?? '학사일정이 없습니다');
    prefs.setInt('$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);

    return notice;
  }

  Future<Map<String, dynamic>?> fetchData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    return jsonDecode(response.body);
  }

  String? processSchoolSchedule(List<dynamic> schoolScheduleArray) {
    for (var i = 0; i < schoolScheduleArray.length; i++) {
      final schedule = schoolScheduleArray[i];
      if (!schedule.containsKey('row')) continue;

      final rowArray = schedule['row'];
      final event = processRow(rowArray);
      if (event != null) return event;
    }

    return '학사일정이 없습니다';
  }

  String? processRow(List<dynamic> rowArray) {
    final filteredRows = rowArray.where((row) => row.containsKey('EVENT_NM'));
    for (var row in filteredRows) {
      if (row['EVENT_NM'] == '토요휴업일') return null;
      return row['EVENT_NM'];
    }

    return null;
  }
}
