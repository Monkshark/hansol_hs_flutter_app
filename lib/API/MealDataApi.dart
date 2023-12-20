import 'dart:async';
import 'dart:convert';

import 'package:hansol_high_school/Network/NetworkStatus.dart';
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

  static const String _MENU = '메뉴';
  static const String _CALORIE = '칼로리';
  static const String _NUTRITION_INFO = '영양정보';

  static String get MENU => _MENU;
  static String get CALORIE => _CALORIE;
  static String get NUTRITION_INFO => _NUTRITION_INFO;

  static String result = '';

  static Future<String> getMeal({
    required DateTime date,
    required int mealType,
    required String type,
  }) async {
    if (await NetworkStatus.isUnconnected()) return "식단 정보를 확인하려면 인터넷에 연결하세요";

    final formattedDate = DateFormat('yyyyMMdd').format(date);
    String requestURL =
        'https://open.neis.go.kr/hub/mealServiceDietInfo?'
        // 'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&MMEAL_SC_CODE=$mealType'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&MLSV_YMD=$formattedDate';

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
            case _MENU:
              result = menu;
              break;
            case _CALORIE:
              result = calorie;
              break;
            case _NUTRITION_INFO:
              result = nutritionInfo;
              break;
          }
        }
      }
    }
    return result.replaceAll('<br/>', '\n');
  }
}
