import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:hansol_high_school/API/NiesApiKeys.dart';

class TimetableDataApi {
  static Future<String?> getTimeTable({
    required DateTime date,
    required String grade,
    required String classNum,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final requestURL =
        'https://open.neis.go.kr/hub/hisTimetable?key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&ALL_TI_YMD=$formattedDate'
        '&GRADE=$grade'
        '&CLASS_NM=$classNum';

    final response = await http.get(Uri.parse(requestURL));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timetableArray = data['hisTimetable'][1]['row'];

      var resultBuilder = StringBuffer();
      if (date.weekday == DateTime.monday) resultBuilder.writeln('자율');

      for (var i = 0; i < timetableArray.length; i++) {
        final itemObject = timetableArray[i];
        final content = itemObject['ITRT_CNTNT'];
        resultBuilder.writeln(content);
      }
      return resultBuilder.toString();
    }
    return "정보 없음";
  }
}
