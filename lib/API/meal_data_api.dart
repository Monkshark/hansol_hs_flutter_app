import 'dart:async';
import 'dart:convert';

import 'package:hansol_high_school/Network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'nies_api_keys.dart';

class MealDataApi {
  static const TAG = 'MealDataApi';

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
    String requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
        '&Type=json&MMEAL_SC_CODE=$mealType'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&MLSV_YMD=$formattedDate';

    print('$TAG :getMeal: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) return '';

    return processMealServiceDietInfo(data['mealServiceDietInfo'], type);
  }

  static Future<Map<String, dynamic>?> fetchData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    return jsonDecode(response.body);
  }

  static String processMealServiceDietInfo(
      List<dynamic> mealServiceDietInfoArray, String type) {
    for (var i = 0; i < mealServiceDietInfoArray.length; i++) {
      final mealServiceDietInfo = mealServiceDietInfoArray[i];
      if (!mealServiceDietInfo.containsKey('row')) continue;

      final rowArray = mealServiceDietInfo['row'];
      final meal = processRow(rowArray, type);
      if (meal != null) return meal;
    }

    return '';
  }

  static String? processRow(List<dynamic> rowArray, String type) {
    for (var row in rowArray) {
      final menu = row['DDISH_NM'];
      final calorie = row['CAL_INFO'];
      final nutritionInfo = row['NTR_INFO'];

      switch (type) {
        case _MENU:
          return menu;
        case _CALORIE:
          return calorie;
        case _NUTRITION_INFO:
          return nutritionInfo;
      }
    }

    return null;
  }
}
