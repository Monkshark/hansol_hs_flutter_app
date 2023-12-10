import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'niesApiKeys.dart';

class mealDataApi {
  static String result = '';

  Future<String> getMeal(String date, String mealScCode, String type) async {
    String requestURL =
        'https://open.neis.go.kr/hub/mealServiceDietInfo?&Type=json&MMEAL_SC_CODE=$mealScCode&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}&MLSV_YMD=$date';

    if (kDebugMode) print('start parse $requestURL');

    final response = await http.get(Uri.parse(requestURL));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final timetableArray = data['mealServiceDietInfo'][1]['row'];

      for (var i = 0; i < timetableArray.length; i++) {
        final itemObject = timetableArray[i];

        final menu = itemObject['DDISH_NM'];
        final calorie = itemObject['CAL_INFO'];
        final nutritionInfo = itemObject['NTR_INFO'];

        switch (type) {
          case '메뉴':
            result = menu;
            break;
          case '칼로리':
            result = calorie;
            break;
          case '영양정보':
            result = nutritionInfo;
            break;
        }
      }
    }
    return result.replaceAll('<br/>', '\n');
  }
}
