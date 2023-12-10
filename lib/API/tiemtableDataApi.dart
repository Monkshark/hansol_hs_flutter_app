import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'niesApiKeys.dart';

class timetableDataAPi {
  static Future<String?> getTimeTable(
      String date, String grade, String classNum) async {
    final requestURL =
        'https://open.neis.go.kr/hub/hisTimetable?&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}&ALL_TI_YMD=$date&GRADE=$grade&CLASS_NM=$classNum';

    if (kDebugMode) print('requestURL: $requestURL');

    final response = await http.get(Uri.parse(requestURL));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timetableArray = data['hisTimetable'][1]['row'];

      final resultBuilder = StringBuffer();
      final dateObj = DateFormat('yyyyMMdd').parse(date);
      if (dateObj.weekday == DateTime.monday) resultBuilder.writeln('자율');

      for (var i = 0; i < timetableArray.length; i++) {
        final itemObject = timetableArray[i];
        final content = itemObject['ITRT_CNTNT'];
        resultBuilder.writeln(content);
      }
      return resultBuilder.toString();
    } else {
      return null;
    }
  }
}
