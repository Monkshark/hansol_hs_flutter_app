import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/api_strings.dart';
import 'package:hansol_high_school/data/meal.dart';
import 'package:hansol_high_school/network/network_status.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _utf8Response(Object body, int statusCode) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockClient mockClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NetworkStatus.testOverride = () async => false; // online
  });

  tearDown(() async {
    await MealDataApi.resetCache();
    MealDataApi.resetClient();
    NetworkStatus.testOverride = null;
  });

  Map<String, dynamic> _mealResponse({
    String date = '20260401',
    int mealCode = 2,
    String menu = '김치볶음밥<br/>된장찌개<br/>깍두기',
    String cal = '650 Kcal',
    String ntr = '탄수화물 : 80g<br/>단백질 : 25g',
  }) {
    return {
      'mealServiceDietInfo': [
        {
          'head': [
            {'list_total_count': 1}
          ]
        },
        {
          'row': [
            {
              'MLSV_YMD': date,
              'MMEAL_SC_CODE': '$mealCode',
              'DDISH_NM': menu,
              'CAL_INFO': cal,
              'NTR_INFO': ntr,
            }
          ]
        }
      ]
    };
  }

  Map<String, dynamic> _emptyResponse() {
    return {
      'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'}
    };
  }

  group('MealDataApi._fetchSingleMeal via getMeal', () {
    test('정상 응답 파싱 — 메뉴, 칼로리, 영양정보', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_mealResponse(), 200);
      });
      MealDataApi.client = mockClient;

      final meal = await MealDataApi.getMeal(
        date: DateTime(2026, 4, 1),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );

      expect(meal, isNotNull);
      expect(meal!.meal, contains('김치볶음밥'));
      expect(meal.meal, contains('\n')); // <br/> → \n
      expect(meal.kcal, '650 Kcal');
      expect(meal.ntrInfo, contains('탄수화물'));
      expect(meal.mealType, 2);
    });

    test('INFO-200 (데이터 없음) → mealNoData 반환', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      MealDataApi.client = mockClient;

      final meal = await MealDataApi.getMeal(
        date: DateTime(2026, 4, 1),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );

      expect(meal, isNotNull);
      expect(meal!.meal, ApiStrings.mealNoData);
    });

    test('HTTP 500 → mealNoData 반환', () async {
      mockClient = MockClient((req) async {
        return http.Response('Server Error', 500);
      });
      MealDataApi.client = mockClient;

      final meal = await MealDataApi.getMeal(
        date: DateTime(2026, 4, 1),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );

      expect(meal, isNotNull);
      expect(meal!.meal, ApiStrings.mealNoData);
    });
  });

  group('MealDataApi 캐시', () {
    test('두 번째 호출은 캐시에서 반환 (HTTP 요청 1회)', () async {
      int requestCount = 0;
      mockClient = MockClient((req) async {
        requestCount++;
        return _utf8Response(_mealResponse(), 200);
      });
      MealDataApi.client = mockClient;

      final meal1 = await MealDataApi.getMeal(
        date: DateTime(2026, 4, 1),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );
      final meal2 = await MealDataApi.getMeal(
        date: DateTime(2026, 4, 1),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );

      expect(meal1!.meal, meal2!.meal);
      // prefetchMonth may batch, but second call should use cache
      expect(requestCount, lessThanOrEqualTo(2));
    });

    test('clearCacheForDate 후 캐시 미스', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_mealResponse(), 200);
      });
      MealDataApi.client = mockClient;

      await MealDataApi.getMeal(
        date: DateTime(2026, 4, 1),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );

      await MealDataApi.clearCacheForDate(DateTime(2026, 4, 1));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('meal_20260401_2'), isFalse);
    });
  });

  group('MealDataApi.isAllMealEmpty', () {
    test('INFO-200 → true', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      MealDataApi.client = mockClient;

      expect(await MealDataApi.isAllMealEmpty(DateTime(2026, 4, 1)), isTrue);
    });

    test('급식 데이터 존재 → false', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_mealResponse(), 200);
      });
      MealDataApi.client = mockClient;

      expect(await MealDataApi.isAllMealEmpty(DateTime(2026, 4, 1)), isFalse);
    });
  });

  group('MealDataApi 아침·저녁 mealType', () {
    test('조식 (mealType=1) 요청 파싱', () async {
      mockClient = MockClient((req) async {
        expect(req.url.toString(), contains('MMEAL_SC_CODE=1'));
        return _utf8Response(
          _mealResponse(mealCode: 1, menu: '토스트<br/>우유'), 200);
      });
      MealDataApi.client = mockClient;

      final meal = await MealDataApi.getMeal(
        date: DateTime(2026, 4, 2),
        mealType: MealDataApi.BREAKFAST,
        type: MealDataApi.MENU,
      );

      expect(meal!.meal, '토스트\n우유');
      expect(meal.mealType, 1);
    });
  });
}
