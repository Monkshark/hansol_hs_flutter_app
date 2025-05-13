import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hansol_high_school/data/meal.dart';
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

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  static Future<Meal?> getMeal({
    required DateTime date,
    required int mealType,
    required String type,
  }) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final cacheKey = '$formattedDate-$mealType-$type';
    final prefs = await _prefs;

    if (prefs.containsKey(cacheKey)) {
      final cachedTimestamp = prefs.getInt('$cacheKey-timestamp') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      const oneDayInMilliseconds = 24 * 60 * 60 * 1000;

      if (currentTime - cachedTimestamp < oneDayInMilliseconds) {
        final mealData = prefs.getString(cacheKey);
        if (mealData != null) {
          return Meal.fromJson(jsonDecode(mealData));
        }
      } else {
        prefs.remove(cacheKey);
        prefs.remove('$cacheKey-timestamp');
      }
    }

    if (await NetworkStatus.isUnconnected()) {
      return Meal(
        meal: "식단 정보를 확인하려면 인터넷에 연결하세요",
        date: date,
        mealType: mealType,
        kcal: '',
      );
    }

    String requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
        '&Type=json&MMEAL_SC_CODE=$mealType'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&MLSV_YMD=$formattedDate';

    log('$TAG :getMeal: $requestURL');

    final data = await fetchData(requestURL);
    if (data == null) {
      final meal =
          Meal(meal: '급식 정보가 없습니다.', date: date, mealType: mealType, kcal: '');
      prefs.setString(cacheKey, jsonEncode(meal.toJson()));
      prefs.setInt(
          '$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
      return meal;
    }

    final meal = processMealServiceDietInfo(
        data['mealServiceDietInfo'], type, date, mealType);

    if (meal != null) {
      prefs.setString(cacheKey, jsonEncode(meal.toJson()));
      prefs.setInt(
          '$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
    } else {
      final meal =
          Meal(meal: '급식 정보가 없습니다.', date: date, mealType: mealType, kcal: '');
      prefs.setString(cacheKey, jsonEncode(meal.toJson()));
      prefs.setInt(
          '$cacheKey-timestamp', DateTime.now().millisecondsSinceEpoch);
    }
    log(meal.toString());

    return meal;
  }

  static Future<Map<String, dynamic>?> fetchData(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic> &&
        data['RESULT'] != null &&
        data['RESULT']['CODE'] == 'INFO-200') {
      return null;
    }

    return data;
  }

  static Meal? processMealServiceDietInfo(
      List<dynamic> mealServiceDietInfoArray,
      String type,
      DateTime date,
      int mealType) {
    for (var i = 0; i < mealServiceDietInfoArray.length; i++) {
      final mealServiceDietInfo = mealServiceDietInfoArray[i];
      if (!mealServiceDietInfo.containsKey('row')) continue;

      final rowArray = mealServiceDietInfo['row'];
      for (var row in rowArray) {
        final menu = row['DDISH_NM'].replaceAll('<br/>', '\n');
        final calorie = row['CAL_INFO'];

        return Meal(
          meal: menu,
          date: date,
          mealType: mealType,
          kcal: calorie,
        );
      }
    }

    return null;
  }

  Future<bool> isAllMealEmpty(DateTime date) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    String requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
        '&Type=json'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&MLSV_YMD=$formattedDate';

    final response = await http.get(Uri.parse(requestURL));

    final data = jsonDecode(response.body);

    if (data.containsKey('RESULT') && data['RESULT']['CODE'] == 'INFO-200') {
      return true;
    }

    if (data.containsKey('mealServiceDietInfo') &&
        data['mealServiceDietInfo'].length > 1 &&
        data['mealServiceDietInfo'][1].containsKey('row')) {
      return data['mealServiceDietInfo'][1]['row'].isEmpty;
    }

    return false;
  }
}
