import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:hansol_high_school/api/notice_data_api.dart';

/// NoticeDataApi의 순수 로직을 테스트
/// 네트워크 의존 메서드는 제외, 데이터 파싱/필터링 로직 검증

String noticeCacheKey(DateTime date) {
  return 'notice_${DateFormat('yyyyMMdd').format(date)}';
}

String monthEventsCacheKey(DateTime month) {
  return 'month_events_v2_${DateFormat('yyyyMM').format(month)}';
}

String? processSchoolSchedule(List<dynamic> schoolScheduleArray) {
  for (var schedule in schoolScheduleArray) {
    if (!schedule.containsKey('row')) continue;
    for (var row in schedule['row']) {
      if (!row.containsKey('EVENT_NM')) continue;
      if (row['EVENT_NM'] == '토요휴업일') return null;
      return row['EVENT_NM'];
    }
  }
  return null;
}

DateTime parseDateStr(String dateStr) {
  return DateTime(
    int.parse(dateStr.substring(0, 4)),
    int.parse(dateStr.substring(4, 6)),
    int.parse(dateStr.substring(6, 8)),
  );
}

List<UpcomingEvent> parseEvents(List<dynamic> infoArray, DateTime today) {
  final events = <UpcomingEvent>[];
  for (var info in infoArray) {
    if (!info.containsKey('row')) continue;
    for (var row in info['row']) {
      if (!row.containsKey('EVENT_NM')) continue;
      final eventName = row['EVENT_NM'] as String;
      if (eventName == '토요휴업일') continue;
      final dateStr = row['AA_YMD'] as String;
      final eventDate = parseDateStr(dateStr);
      final dDay = eventDate.difference(today).inDays;
      if (dDay >= 0) {
        events.add(UpcomingEvent(name: eventName, date: eventDate, dDay: dDay));
      }
    }
  }
  events.sort((a, b) => a.dDay.compareTo(b.dDay));
  return events;
}

void main() {
  group('NoticeDataApi cache key', () {
    test('generates correct format', () {
      expect(noticeCacheKey(DateTime(2026, 4, 12)), 'notice_20260412');
    });

    test('pads single digit month and day', () {
      expect(noticeCacheKey(DateTime(2026, 1, 5)), 'notice_20260105');
    });

    test('different dates produce different keys', () {
      expect(noticeCacheKey(DateTime(2026, 4, 1)) != noticeCacheKey(DateTime(2026, 4, 2)), true);
    });
  });

  group('NoticeDataApi month events cache key', () {
    test('generates correct format', () {
      expect(monthEventsCacheKey(DateTime(2026, 4, 1)), 'month_events_v2_202604');
    });

    test('pads single digit month', () {
      expect(monthEventsCacheKey(DateTime(2026, 1, 15)), 'month_events_v2_202601');
    });
  });

  group('processSchoolSchedule', () {
    test('returns first event name', () {
      final data = [
        {'row': [{'EVENT_NM': '중간고사'}]}
      ];
      expect(processSchoolSchedule(data), '중간고사');
    });

    test('returns null for 토요휴업일', () {
      final data = [
        {'row': [{'EVENT_NM': '토요휴업일'}]}
      ];
      expect(processSchoolSchedule(data), null);
    });

    test('returns null when no row key', () {
      final data = [{'other': 'data'}];
      expect(processSchoolSchedule(data), null);
    });

    test('returns null when no EVENT_NM key', () {
      final data = [
        {'row': [{'OTHER_FIELD': 'value'}]}
      ];
      expect(processSchoolSchedule(data), null);
    });

    test('returns null for empty array', () {
      expect(processSchoolSchedule([]), null);
    });

    test('skips entries without row and finds next', () {
      final data = [
        {'other': 'data'},
        {'row': [{'EVENT_NM': '기말고사'}]},
      ];
      expect(processSchoolSchedule(data), '기말고사');
    });
  });

  group('parseDateStr', () {
    test('parses YYYYMMDD correctly', () {
      final date = parseDateStr('20260510');
      expect(date.year, 2026);
      expect(date.month, 5);
      expect(date.day, 10);
    });

    test('parses single digit month/day', () {
      final date = parseDateStr('20260105');
      expect(date.month, 1);
      expect(date.day, 5);
    });
  });

  group('parseEvents', () {
    final today = DateTime(2026, 4, 12);

    test('parses valid events and calculates dDay', () {
      final data = [
        {
          'row': [
            {'EVENT_NM': '중간고사', 'AA_YMD': '20260420'},
            {'EVENT_NM': '기말고사', 'AA_YMD': '20260710'},
          ]
        }
      ];
      final events = parseEvents(data, today);
      expect(events.length, 2);
      expect(events[0].name, '중간고사');
      expect(events[0].dDay, 8);
      expect(events[1].name, '기말고사');
    });

    test('filters out 토요휴업일', () {
      final data = [
        {
          'row': [
            {'EVENT_NM': '토요휴업일', 'AA_YMD': '20260418'},
            {'EVENT_NM': '중간고사', 'AA_YMD': '20260420'},
          ]
        }
      ];
      final events = parseEvents(data, today);
      expect(events.length, 1);
      expect(events[0].name, '중간고사');
    });

    test('filters out past events', () {
      final data = [
        {
          'row': [
            {'EVENT_NM': '개학', 'AA_YMD': '20260301'},
            {'EVENT_NM': '중간고사', 'AA_YMD': '20260420'},
          ]
        }
      ];
      final events = parseEvents(data, today);
      expect(events.length, 1);
      expect(events[0].name, '중간고사');
    });

    test('includes today events (dDay == 0)', () {
      final data = [
        {
          'row': [
            {'EVENT_NM': '오늘행사', 'AA_YMD': '20260412'},
          ]
        }
      ];
      final events = parseEvents(data, today);
      expect(events.length, 1);
      expect(events[0].dDay, 0);
    });

    test('sorts by dDay ascending', () {
      final data = [
        {
          'row': [
            {'EVENT_NM': '기말고사', 'AA_YMD': '20260710'},
            {'EVENT_NM': '중간고사', 'AA_YMD': '20260420'},
          ]
        }
      ];
      final events = parseEvents(data, today);
      expect(events[0].name, '중간고사');
      expect(events[1].name, '기말고사');
    });

    test('returns empty for entries without row', () {
      expect(parseEvents([{'other': 'data'}], today), isEmpty);
    });

    test('returns empty for empty array', () {
      expect(parseEvents([], today), isEmpty);
    });
  });

  group('UpcomingEvent', () {
    test('stores name, date, and dDay', () {
      final event = UpcomingEvent(
        name: '중간고사',
        date: DateTime(2026, 5, 10),
        dDay: 28,
      );
      expect(event.name, '중간고사');
      expect(event.date.month, 5);
      expect(event.dDay, 28);
    });
  });
}
