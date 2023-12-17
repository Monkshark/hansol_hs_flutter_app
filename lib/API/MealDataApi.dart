import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'NiesApiKeys.dart';

class MealDataApi {
  static const int _BREAKFAST = 1;
  static const int _LUNCH = 2;
  static const int _DINNER = 3;

  static int get BREAKFAST => _BREAKFAST;
  static int get LUNCH => _LUNCH;
  static int get DINNER => _DINNER;

  static String result = '';

  static Future<String> getMeal({
    required DateTime date,
    required int mealType,
    required String type,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    String requestURL =
        'https://open.neis.go.kr/hub/mealServiceDietInfo?&Type=json&MMEAL_SC_CODE=$mealType&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}&MLSV_YMD=$formattedDate';

    print('start parse $requestURL');

    final response = await http.get(Uri.parse(requestURL));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data != null && data.containsKey('mealServiceDietInfo')) {
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
    }
    result ??= '정보 없음';
    return result.replaceAll('<br/>', '\n');
  }
}
