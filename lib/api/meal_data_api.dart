import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hansol_high_school/data/api_strings.dart';
import 'package:hansol_high_school/data/exceptions.dart';
import 'package:hansol_high_school/data/meal.dart';
import 'nies_api_keys.dart';

class MealDataApi {
  static http.Client _client = http.Client();

  @visibleForTesting
  static set client(http.Client c) => _client = c;

  @visibleForTesting
  static void resetClient() => _client = http.Client();

  @visibleForTesting
  static Future<void> resetCache() async {
    _prefetchingMonths.clear();
    final prefs = await _prefs;
    await prefs.clear();
  }

  static const int BREAKFAST = 1;
  static const int LUNCH = 2;
  static const int DINNER = 3;

  static const String MENU = '메뉴';
  static const String CALORIE = '칼로리';
  static const String NUTRITION_INFO = '영양정보';

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  static final Map<String, Future<void>> _prefetchingMonths = {};

  static Future<Meal?> getMeal({
    required DateTime date,
    required int mealType,
    required String type,
  }) async {
    final prefs = await _prefs;
    final cacheKey = _cacheKey(date, mealType);
    log('MealDataApi: getMeal cacheKey=$cacheKey');

    final cached = _getFromCache(prefs, cacheKey);
    if (cached != null && cached.meal != null && cached.meal != ApiStrings.mealNoData && cached.meal != ApiStrings.mealNoDataLegacy) {
      if (_isCacheStale(prefs, cacheKey)) {
        log('MealDataApi: getMeal stale cache, revalidating in background');
        _prefetchMonth(date);
      } else {
        log('MealDataApi: getMeal cache hit: ${cached.meal?.substring(0, cached.meal!.length > 20 ? 20 : cached.meal!.length)}');
      }
      return cached;
    }
    log('MealDataApi: getMeal cache miss');

    if (await NetworkStatus.isUnconnected()) {
      if (cached != null) return cached;
      return Meal(
        meal: ApiStrings.mealNoInternet,
        date: date,
        mealType: mealType,
        kcal: '',
      );
    }

    await _prefetchMonth(date);

    final afterPrefetch = _getFromCache(prefs, cacheKey);
    if (afterPrefetch != null) {
      log('MealDataApi: getMeal after prefetch hit');
      return afterPrefetch;
    }
    log('MealDataApi: getMeal after prefetch miss, falling back to single');

    return _fetchSingleMeal(date, mealType, prefs, cacheKey);
  }

  static Future<Meal> _fetchSingleMeal(
      DateTime date, int mealType, SharedPreferences prefs, String cacheKey) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
        'key=${NiesApiKeys.niesApiKey}'
        '&Type=json&MMEAL_SC_CODE=$mealType'
        '&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
        '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
        '&MLSV_YMD=$formattedDate';

    try {
      final data = await _fetchData(requestURL);
      if (!data.containsKey('mealServiceDietInfo')) {
        final empty = Meal(meal: ApiStrings.mealNoData, date: date, mealType: mealType, kcal: '');
        _saveToCache(prefs, cacheKey, empty);
        return empty;
      }

      final infoArray = data['mealServiceDietInfo'] as List<dynamic>;
      for (var info in infoArray) {
        if (!info.containsKey('row')) continue;
        for (var row in info['row']) {
          final meal = Meal(
            meal: (row['DDISH_NM'] as String).replaceAll('<br/>', '\n'),
            date: date,
            mealType: mealType,
            kcal: row['CAL_INFO'] as String,
            ntrInfo: (row['NTR_INFO'] as String?)?.replaceAll('<br/>', '\n') ?? '',
          );
          _saveToCache(prefs, cacheKey, meal);
          return meal;
        }
      }

      final empty = Meal(meal: ApiStrings.mealNoData, date: date, mealType: mealType, kcal: '');
      _saveToCache(prefs, cacheKey, empty);
      return empty;
    } on NetworkException {
      final empty = Meal(meal: ApiStrings.mealNoData, date: date, mealType: mealType, kcal: '');
      _saveToCache(prefs, cacheKey, empty);
      return empty;
    }
  }

  static Future<void> _prefetchMonth(DateTime date) async {
    final monthKey = DateFormat('yyyyMM').format(date);

    if (_prefetchingMonths.containsKey(monthKey)) {
      await _prefetchingMonths[monthKey];
      return;
    }

    final completer = Completer<void>();
    _prefetchingMonths[monthKey] = completer.future;

    try {
      final prefs = await _prefs;
      final firstDay = DateTime(date.year, date.month, 1);
      final lastDay = DateTime(date.year, date.month + 1, 0);

      final fromDate = DateFormat('yyyyMMdd').format(firstDay);
      final toDate = DateFormat('yyyyMMdd').format(lastDay);

      final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
          'key=${NiesApiKeys.niesApiKey}'
          '&Type=json&pIndex=1&pSize=100'
          '&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
          '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
          '&MLSV_FROM_YMD=$fromDate'
          '&MLSV_TO_YMD=$toDate';

      log('MealDataApi: prefetch $monthKey ($fromDate~$toDate)');

      late final Map<String, dynamic> data;
      try {
        data = await _fetchData(requestURL);
      } on NetworkException catch (e) {
        log('MealDataApi: prefetch $monthKey - network error: $e');
        completer.complete();
        return;
      }

      log('MealDataApi: prefetch $monthKey - keys: ${data.keys.toList()}');

      if (!data.containsKey('mealServiceDietInfo')) {
        log('MealDataApi: prefetch $monthKey - no mealServiceDietInfo key');
        completer.complete();
        return;
      }

      final infoArray = data['mealServiceDietInfo'] as List<dynamic>;
      int count = 0;

      for (var info in infoArray) {
        if (!info.containsKey('row')) continue;
        for (var row in info['row']) {
          final dateStr = row['MLSV_YMD'] as String;
          final mealCode = int.parse(row['MMEAL_SC_CODE'] as String);
          final menu = (row['DDISH_NM'] as String).replaceAll('<br/>', '\n');
          final calorie = row['CAL_INFO'] as String;
          final mealDate = DateTime(
            int.parse(dateStr.substring(0, 4)),
            int.parse(dateStr.substring(4, 6)),
            int.parse(dateStr.substring(6, 8)),
          );

          final ntrInfo = (row['NTR_INFO'] as String?)?.replaceAll('<br/>', '\n') ?? '';
          final meal = Meal(
            meal: menu,
            date: mealDate,
            mealType: mealCode,
            kcal: calorie,
            ntrInfo: ntrInfo,
          );

          final key = _cacheKey(mealDate, mealCode);
          _saveToCache(prefs, key, meal);
          count++;
        }
      }

      log('MealDataApi: prefetch $monthKey - cached $count meals');
      completer.complete();
    } catch (e) {
      log('MealDataApi: prefetch error: $e');
      completer.completeError(e);
    } finally {
      _prefetchingMonths.remove(monthKey);
    }
  }

  static Future<void> prefetchWeek(DateTime baseDate) async {
    final monday = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    if (monday.month == friday.month) {
      await _prefetchMonth(monday);
    } else {
      await Future.wait([
        _prefetchMonth(monday),
        _prefetchMonth(friday),
      ]);
    }
  }

  static String _cacheKey(DateTime date, int mealType) {
    return 'meal_${DateFormat('yyyyMMdd').format(date)}_$mealType';
  }

  static Meal? _getFromCache(SharedPreferences prefs, String key) {
    if (!prefs.containsKey(key)) return null;
    final ts = prefs.getInt('$key-ts') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;

    final data = prefs.getString(key);
    if (data == null) return null;

    final meal = Meal.fromJson(jsonDecode(data));

    if (meal.meal == ApiStrings.mealNoData) {
      if (age > 5 * 60 * 1000) return null;
    } else if (age > 24 * 60 * 60 * 1000) {
      if (age > 3 * 24 * 60 * 60 * 1000) return null;
    }

    return meal;
  }

  static bool _isCacheStale(SharedPreferences prefs, String key) {
    final ts = prefs.getInt('$key-ts') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    return age > 24 * 60 * 60 * 1000;
  }

  static void _saveToCache(SharedPreferences prefs, String key, Meal meal) {
    prefs.setString(key, jsonEncode(meal.toJson()));
    prefs.setInt('$key-ts', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearCacheForDate(DateTime date) async {
    final prefs = await _prefs;
    for (final type in [BREAKFAST, LUNCH, DINNER]) {
      final key = _cacheKey(date, type);
      prefs.remove(key);
      prefs.remove('$key-ts');
    }
  }

  static Future<Map<String, dynamic>> _fetchData(String url) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw NetworkException('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> &&
          data['RESULT'] != null &&
          data['RESULT']['CODE'] == 'INFO-200') {
        return data;
      }
      return data;
    } on NetworkException {
      rethrow;
    } on TimeoutException catch (e) {
      log('MealDataApi: fetch timeout');
      throw NetworkException('요청 시간 초과', e);
    } catch (e) {
      log('MealDataApi: fetch error: $e');
      throw NetworkException('API 요청 실패', e);
    }
  }

  static Future<bool> isAllMealEmpty(DateTime date) async {
    try {
      final formattedDate = DateFormat('yyyyMMdd').format(date);
      final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
          '&Type=json'
          '&ATPT_OFCDC_SC_CODE=${NiesApiKeys.atptOfcdcScCode}'
          '&SD_SCHUL_CODE=${NiesApiKeys.sdSchulCode}'
          '&MLSV_YMD=$formattedDate';

      final response = await _client.get(Uri.parse(requestURL)).timeout(const Duration(seconds: 10));
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
    } on TimeoutException {
      log('MealDataApi: isAllMealEmpty timeout');
      return false;
    } catch (e) {
      log('MealDataApi: isAllMealEmpty error: $e');
      return false;
    }
  }
}
