import 'dart:async';
import 'dart:convert';

import 'package:hansol_high_school/Network/NetworkStatus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'NiesApiKeys.dart';

class NoticeDataApi {
  static const TAG = 'NoticeDataApi';

  Future<String?> getNotice({
    required DateTime date,
  }) async {
    if (await NetworkStatus.isUnconnected()) return "학사일정을 확인하려면 인터넷에 연결하세요";

    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final requestURL = 'https://open.neis.go.kr/hub/SchoolSchedule?'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        // 'key=${niesApiKeys.NIES_API_KEY}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&AA_YMD=$formattedDate';

    print('$TAG: getNotice: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) return null;

    return processSchoolSchedule(data['SchoolSchedule']);
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

    return null;
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
