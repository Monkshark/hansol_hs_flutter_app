import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';
import 'package:hansol_high_school/data/api_strings.dart';
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

  late NoticeDataApi api;
  late MockClient mockClient;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NetworkStatus.testOverride = () async => false; // online
    api = NoticeDataApi();
  });

  tearDown(() {
    NoticeDataApi.resetClient();
    NetworkStatus.testOverride = null;
  });

  Map<String, dynamic> _scheduleResponse(String eventName) {
    return {
      'SchoolSchedule': [
        {
          'head': [
            {'list_total_count': 1}
          ]
        },
        {
          'row': [
            {
              'AA_YMD': '20260401',
              'EVENT_NM': eventName,
            }
          ]
        }
      ]
    };
  }

  Map<String, dynamic> _multiEventResponse(List<Map<String, String>> events) {
    return {
      'SchoolSchedule': [
        {
          'head': [
            {'list_total_count': events.length}
          ]
        },
        {
          'row': events
              .map((e) => {'AA_YMD': e['date'], 'EVENT_NM': e['name']})
              .toList(),
        }
      ]
    };
  }

  Map<String, dynamic> _emptyResponse() {
    return {
      'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'}
    };
  }

  group('NoticeDataApi.getNotice', () {
    test('정상 학사일정 파싱', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_scheduleResponse('중간고사'), 200);
      });
      NoticeDataApi.client = mockClient;

      final notice = await api.getNotice(date: DateTime(2026, 4, 1));
      expect(notice, '중간고사');
    });

    test('INFO-200 → noticeNoData', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      NoticeDataApi.client = mockClient;

      final notice = await api.getNotice(date: DateTime(2026, 4, 1));
      expect(notice, ApiStrings.noticeNoData);
    });

    test('토요휴업일 → null', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_scheduleResponse('토요휴업일'), 200);
      });
      NoticeDataApi.client = mockClient;

      final notice = await api.getNotice(date: DateTime(2026, 4, 4));
      expect(notice, isNull);
    });

    test('HTTP 500 → noticeNoData', () async {
      mockClient = MockClient((req) async {
        return http.Response('Internal Server Error', 500);
      });
      NoticeDataApi.client = mockClient;

      final notice = await api.getNotice(date: DateTime(2026, 4, 1));
      expect(notice, ApiStrings.noticeNoData);
    });

    test('캐시 히트 — 두 번째 호출 시 HTTP 요청 없음', () async {
      int requestCount = 0;
      mockClient = MockClient((req) async {
        requestCount++;
        return _utf8Response(_scheduleResponse('개교기념일'), 200);
      });
      NoticeDataApi.client = mockClient;

      await api.getNotice(date: DateTime(2026, 4, 1));
      final second = await api.getNotice(date: DateTime(2026, 4, 1));

      expect(second, '개교기념일');
      expect(requestCount, 1);
    });
  });

  group('NoticeDataApi.getUpcomingEvent', () {
    test('가장 가까운 이벤트 반환', () async {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final dayAfter = DateTime.now().add(const Duration(days: 3));
      final tomorrowStr =
          '${tomorrow.year}${tomorrow.month.toString().padLeft(2, '0')}${tomorrow.day.toString().padLeft(2, '0')}';
      final dayAfterStr =
          '${dayAfter.year}${dayAfter.month.toString().padLeft(2, '0')}${dayAfter.day.toString().padLeft(2, '0')}';

      mockClient = MockClient((req) async {
        return _utf8Response(_multiEventResponse([
            {'date': dayAfterStr, 'name': '체육대회'},
            {'date': tomorrowStr, 'name': '중간고사'},
          ]), 200);
      });
      NoticeDataApi.client = mockClient;

      final event = await api.getUpcomingEvent();
      expect(event, isNotNull);
      expect(event!.name, '중간고사');
      expect(event.dDay, 1);
    });

    test('데이터 없음 → null', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      NoticeDataApi.client = mockClient;

      final event = await api.getUpcomingEvent();
      expect(event, isNull);
    });
  });

  group('NoticeDataApi.getMonthEvents', () {
    test('월간 이벤트 맵 반환', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_multiEventResponse([
            {'date': '20260401', 'name': '중간고사'},
            {'date': '20260415', 'name': '현장학습'},
          ]), 200);
      });
      NoticeDataApi.client = mockClient;

      final events = await api.getMonthEvents(DateTime(2026, 4));
      expect(events.length, 2);
      expect(events[DateTime(2026, 4, 1)], '중간고사');
      expect(events[DateTime(2026, 4, 15)], '현장학습');
    });

    test('빈 월 → 빈 맵', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      NoticeDataApi.client = mockClient;

      final events = await api.getMonthEvents(DateTime(2026, 8));
      expect(events, isEmpty);
    });

    test('토요휴업일 필터링', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_multiEventResponse([
            {'date': '20260404', 'name': '토요휴업일'},
            {'date': '20260405', 'name': '어린이날'},
          ]), 200);
      });
      NoticeDataApi.client = mockClient;

      final events = await api.getMonthEvents(DateTime(2026, 4));
      expect(events.length, 1);
      expect(events[DateTime(2026, 4, 5)], '어린이날');
    });
  });

  group('NoticeDataApi.getEventsInRange', () {
    test('범위 내 이벤트 정렬 반환', () async {
      final d1 = DateTime.now().add(const Duration(days: 5));
      final d2 = DateTime.now().add(const Duration(days: 2));
      final fmt = (DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

      mockClient = MockClient((req) async {
        return _utf8Response(_multiEventResponse([
            {'date': fmt(d1), 'name': '체육대회'},
            {'date': fmt(d2), 'name': '중간고사'},
          ]), 200);
      });
      NoticeDataApi.client = mockClient;

      final events = await api.getEventsInRange(days: 30);
      expect(events.length, 2);
      expect(events.first.name, '중간고사'); // 더 가까운 이벤트가 먼저
      expect(events.first.dDay, lessThan(events.last.dDay));
    });
  });
}
