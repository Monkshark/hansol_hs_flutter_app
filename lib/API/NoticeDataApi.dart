import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'NiesApiKeys.dart';

class NoticeDataApi {
  static const TAG = 'getNoticeData';

  Future<String?> getNotice({
    required DateTime date,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final requestURL =
        'https://open.neis.go.kr/hub/SchoolSchedule?&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}&AA_YMD=$formattedDate';

    print('$TAG: getNotice: $date');

    final response = await http.get(Uri.parse(requestURL));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data.containsKey('SchoolSchedule')) {
        final schoolScheduleArray = data['SchoolSchedule'];

        for (var i = 0; i < schoolScheduleArray.length; i++) {
          final schedule = schoolScheduleArray[i];
          if (schedule.containsKey('row')) {
            final rowArray = schedule['row'];
            for (var j = 0; j < rowArray.length; j++) {
              final row = rowArray[j];
              if (row.containsKey('EVENT_NM')) {
                if (row['EVENT_NM'] == '토요휴업일') return null;
                return row['EVENT_NM'];
              }
            }
          }
        }
      }
    }
    return null;
  }
}
