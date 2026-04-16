import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/api_strings.dart';

void main() {
  group('ApiStrings 상수', () {
    group('meal', () {
      test('mealNoData 값', () {
        expect(ApiStrings.mealNoData, '급식 정보가 없습니다.');
      });

      test('mealNoDataLegacy 값', () {
        expect(ApiStrings.mealNoDataLegacy, '급식 정보가 없습니다');
      });

      test('mealNoData vs mealNoDataLegacy — 마침표 차이', () {
        expect(ApiStrings.mealNoData, isNot(ApiStrings.mealNoDataLegacy));
        expect(ApiStrings.mealNoData, startsWith(ApiStrings.mealNoDataLegacy));
      });

      test('mealNoInternet 값', () {
        expect(ApiStrings.mealNoInternet, '식단 정보를 확인하려면 인터넷에 연결하세요');
      });
    });

    group('timetable', () {
      test('timetableNoInternet 값', () {
        expect(ApiStrings.timetableNoInternet, '시간표를 확인하려면 인터넷에 연결하세요');
      });

      test('timetableNoData 값', () {
        expect(ApiStrings.timetableNoData, '정보 없음');
      });
    });

    group('notice', () {
      test('noticeNoInternet 값', () {
        expect(ApiStrings.noticeNoInternet, '학사일정을 확인하려면 인터넷에 연결하세요');
      });

      test('noticeNoData 값', () {
        expect(ApiStrings.noticeNoData, '학사일정이 없습니다');
      });
    });

    group('센티널 비교', () {
      test('== 비교로 데이터 유무 판별', () {
        const serverResponse = '급식 정보가 없습니다.';
        expect(serverResponse == ApiStrings.mealNoData, isTrue);
      });

      test('실제 급식 데이터와 구분', () {
        const realMeal = '현미밥\n돈까스\n김치';
        expect(realMeal == ApiStrings.mealNoData, isFalse);
      });

      test('인터넷 없음 메시지와 데이터 없음 구분', () {
        expect(ApiStrings.mealNoInternet == ApiStrings.mealNoData, isFalse);
      });
    });
  });
}
