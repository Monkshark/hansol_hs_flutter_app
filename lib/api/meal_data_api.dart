import 'dart:convert';
import 'dart:developer';

import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hansol_high_school/data/meal.dart';
import 'nies_api_keys.dart';

class MealDataApi {
  static const int BREAKFAST = 1;
  static const int LUNCH = 2;
  static const int DINNER = 3;

  static const String MENU = '메뉴';
  static const String CALORIE = '칼로리';
  static const String NUTRITION_INFO = '영양정보';

  static final Future<SharedPreferences> _prefs =
      SharedPreferences.getInstance();

  // 현재 프리페치 중인 월을 추적해서 중복 요청 방지
  static final Set<String> _prefetchingMonths = {};

  /// 단일 날짜 급식 조회 (캐시 우선, 없으면 해당 월 전체 프리페치)
  static Future<Meal?> getMeal({
    required DateTime date,
    required int mealType,
    required String type,
  }) async {
    final prefs = await _prefs;
    final cacheKey = _cacheKey(date, mealType);
    log('MealDataApi: getMeal cacheKey=$cacheKey');

    // 1. 캐시 확인 (실제 데이터만 hit, 빈 결과는 무시)
    final cached = _getFromCache(prefs, cacheKey);
    if (cached != null && cached.meal != null && cached.meal != '급식 정보가 없습니다.' && cached.meal != '급식 정보가 없습니다') {
      log('MealDataApi: getMeal cache hit: ${cached.meal?.substring(0, cached.meal!.length > 20 ? 20 : cached.meal!.length)}');
      return cached;
    }
    log('MealDataApi: getMeal cache miss');

    // 2. 오프라인 체크
    if (await NetworkStatus.isUnconnected()) {
      // 오프라인이면 빈 캐시라도 반환
      if (cached != null) return cached;
      return Meal(
        meal: "식단 정보를 확인하려면 인터넷에 연결하세요",
        date: date,
        mealType: mealType,
        kcal: '',
      );
    }

    // 3. 해당 월 전체 프리페치 (한 번만)
    await _prefetchMonth(date);

    // 4. 프리페치 후 캐시 다시 확인
    final afterPrefetch = _getFromCache(prefs, cacheKey);
    if (afterPrefetch != null) {
      log('MealDataApi: getMeal after prefetch hit');
      return afterPrefetch;
    }
    log('MealDataApi: getMeal after prefetch miss, falling back to single');

    // 5. 폴백: 단일 날짜 직접 조회
    return _fetchSingleMeal(date, mealType, prefs, cacheKey);
  }

  static Future<Meal> _fetchSingleMeal(
      DateTime date, int mealType, SharedPreferences prefs, String cacheKey) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
        'key=${niesApiKeys.NIES_API_KEY}'
        '&Type=json&MMEAL_SC_CODE=$mealType'
        '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
        '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
        '&MLSV_YMD=$formattedDate';

    final data = await _fetchData(requestURL);
    if (data == null || !data.containsKey('mealServiceDietInfo')) {
      final empty = Meal(meal: '급식 정보가 없습니다.', date: date, mealType: mealType, kcal: '');
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
        );
        _saveToCache(prefs, cacheKey, meal);
        return meal;
      }
    }

    final empty = Meal(meal: '급식 정보가 없습니다.', date: date, mealType: mealType, kcal: '');
    _saveToCache(prefs, cacheKey, empty);
    return empty;
  }

  /// 해당 월의 모든 급식을 한 번에 가져와서 캐싱
  static Future<void> _prefetchMonth(DateTime date) async {
    final monthKey = DateFormat('yyyyMM').format(date);

    // 이미 프리페치 중이면 대기
    if (_prefetchingMonths.contains(monthKey)) return;
    _prefetchingMonths.add(monthKey);

    try {
      final prefs = await _prefs;
      final firstDay = DateTime(date.year, date.month, 1);
      final lastDay = DateTime(date.year, date.month + 1, 0);

      final fromDate = DateFormat('yyyyMMdd').format(firstDay);
      final toDate = DateFormat('yyyyMMdd').format(lastDay);

      // 조식/중식/석식 전부 한 번에 (MMEAL_SC_CODE 없이 요청하면 전체)
      final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
          'key=${niesApiKeys.NIES_API_KEY}'
          '&Type=json&pIndex=1&pSize=100'
          '&ATPT_OFCDC_SC_CODE=${niesApiKeys.ATPT_OFCDC_SC_CODE}'
          '&SD_SCHUL_CODE=${niesApiKeys.SD_SCHUL_CODE}'
          '&MLSV_FROM_YMD=$fromDate'
          '&MLSV_TO_YMD=$toDate';

      log('MealDataApi: prefetch $monthKey ($fromDate~$toDate)');

      final data = await _fetchData(requestURL);
      if (data == null) {
        log('MealDataApi: prefetch $monthKey - no data (null response)');
        return;
      }

      log('MealDataApi: prefetch $monthKey - keys: ${data.keys.toList()}');

      if (!data.containsKey('mealServiceDietInfo')) {
        log('MealDataApi: prefetch $monthKey - no mealServiceDietInfo key');
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

          final meal = Meal(
            meal: menu,
            date: mealDate,
            mealType: mealCode,
            kcal: calorie,
          );

          final key = _cacheKey(mealDate, mealCode);
          // 항상 실제 데이터로 덮어씀 (빈 캐시 포함)
          _saveToCache(prefs, key, meal);
          count++;
        }
      }

      log('MealDataApi: prefetch $monthKey - cached $count meals');
    } catch (e) {
      log('MealDataApi: prefetch error: $e');
    } finally {
      _prefetchingMonths.remove(monthKey);
    }
  }

  /// 주간 프리페치 (급식 화면 진입 시 호출용)
  static Future<void> prefetchWeek(DateTime baseDate) async {
    final monday = baseDate.subtract(Duration(days: baseDate.weekday - 1));
    final friday = monday.add(const Duration(days: 4));

    // 같은 월이면 월간 프리페치 한 번으로 충분
    if (monday.month == friday.month) {
      await _prefetchMonth(monday);
    } else {
      // 주가 월을 걸치면 두 달 프리페치
      await Future.wait([
        _prefetchMonth(monday),
        _prefetchMonth(friday),
      ]);
    }
  }

  static String _cacheKey(DateTime date, int mealType) {
    return 'meal_${DateFormat('yyyyMMdd').format(date)}_$mealType';
  }

  static bool _isCacheValid(SharedPreferences prefs, String key) {
    if (!prefs.containsKey(key)) return false;
    final ts = prefs.getInt('$key-ts') ?? 0;
    return DateTime.now().millisecondsSinceEpoch - ts < 24 * 60 * 60 * 1000;
  }

  static Meal? _getFromCache(SharedPreferences prefs, String key) {
    if (!prefs.containsKey(key)) return null;
    final ts = prefs.getInt('$key-ts') ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - ts;

    final data = prefs.getString(key);
    if (data == null) return null;

    final meal = Meal.fromJson(jsonDecode(data));

    // 실제 급식 데이터는 24시간 캐시
    // "급식 정보가 없습니다." 는 5분만 캐시 (프리페치로 덮어쓸 수 있도록)
    if (meal.meal == '급식 정보가 없습니다.') {
      if (age > 5 * 60 * 1000) return null;
    } else {
      if (age > 24 * 60 * 60 * 1000) return null;
    }

    return meal;
  }

  static void _saveToCache(SharedPreferences prefs, String key, Meal meal) {
    prefs.setString(key, jsonEncode(meal.toJson()));
    prefs.setInt('$key-ts', DateTime.now().millisecondsSinceEpoch);
  }

  /// 특정 날짜의 모든 급식 캐시 삭제
  static Future<void> clearCacheForDate(DateTime date) async {
    final prefs = await _prefs;
    for (final type in [BREAKFAST, LUNCH, DINNER]) {
      final key = _cacheKey(date, type);
      prefs.remove(key);
      prefs.remove('$key-ts');
    }
  }

  static Future<Map<String, dynamic>?> _fetchData(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> &&
          data['RESULT'] != null &&
          data['RESULT']['CODE'] == 'INFO-200') {
        return null;
      }
      return data;
    } catch (e) {
      log('MealDataApi: fetch error: $e');
      return null;
    }
  }

  static Future<bool> isAllMealEmpty(DateTime date) async {
    final formattedDate = DateFormat('yyyyMMdd').format(date);
    final requestURL = 'https://open.neis.go.kr/hub/mealServiceDietInfo?'
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
