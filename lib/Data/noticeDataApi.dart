import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'niesApiKeys.dart';

class GetNoticeData {
  static const TAG = 'getNoticeData';

  Future<String> getNotice(String date) async {
    final requestURL =
        'https://open.neis.go.kr/hub/SchoolSchedule?&Type=json&ATPT_OFCDC_SC_CODE=${niesAPI.ATPT_OFCDC_SC_CODE}&SD_SCHUL_CODE=${niesAPI.SD_SCHUL_CODE}&AA_YMD=$date';

    if (kDebugMode) print('$TAG: getNotice: $date');

    final response = await http.get(Uri.parse(requestURL));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final schoolScheduleArray = data['SchoolSchedule'];

      for (var i = 0; i < schoolScheduleArray.length; i++) {
        final schedule = schoolScheduleArray[i];
        if (schedule.containsKey('row')) {
          final rowArray = schedule['row'];
          for (var j = 0; j < rowArray.length; j++) {
            final row = rowArray[j];
            if (row.containsKey('EVENT_NM')) {
              return row['EVENT_NM'];
            }
          }
        }
      }
    }
    return '학사일정 없음';
  }
}
