import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/api/timetable_data_api.dart';
import 'package:hansol_high_school/data/api_strings.dart';
import 'package:hansol_high_school/data/subject.dart';
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

  tearDown(() {
    TimetableDataApi.resetClient();
    NetworkStatus.testOverride = null;
  });

  Map<String, dynamic> _timetableResponse({
    List<Map<String, dynamic>>? rows,
  }) {
    rows ??= [
      {
        'ALL_TI_YMD': '20260401',
        'CLASS_NM': '1',
        'PERIO': '1',
        'ITRT_CNTNT': '국어',
      },
      {
        'ALL_TI_YMD': '20260401',
        'CLASS_NM': '1',
        'PERIO': '2',
        'ITRT_CNTNT': '수학',
      },
      {
        'ALL_TI_YMD': '20260401',
        'CLASS_NM': '2',
        'PERIO': '1',
        'ITRT_CNTNT': '영어',
      },
      {
        'ALL_TI_YMD': '20260402',
        'CLASS_NM': '1',
        'PERIO': '1',
        'ITRT_CNTNT': '과학',
      },
    ];
    return {
      'hisTimetable': [
        {
          'head': [
            {'list_total_count': rows.length}
          ]
        },
        {'row': rows}
      ]
    };
  }

  Map<String, dynamic> _emptyResponse() {
    return {
      'RESULT': {'CODE': 'INFO-200', 'MESSAGE': '해당하는 데이터가 없습니다.'}
    };
  }

  group('TimetableDataApi.getTimeTable', () {
    test('정상 시간표 파싱 — 날짜별·반별 과목 배열', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(), 200);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
        grade: '1',
      );

      expect(result.containsKey('error'), isFalse);
      expect(result['20260401']!['1']![0], '국어');
      expect(result['20260401']!['1']![1], '수학');
      expect(result['20260401']!['2']![0], '영어');
      expect(result['20260402']!['1']![0], '과학');
    });

    test('INFO-200 (데이터 없음) → error 맵', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
        grade: '1',
      );

      expect(result.containsKey('error'), isTrue);
      expect(result['error']!['error']!.first, ApiStrings.timetableNoData);
    });

    test('HTTP 500 → error 맵', () async {
      mockClient = MockClient((req) async {
        return http.Response('Server Error', 500);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
        grade: '1',
      );

      expect(result.containsKey('error'), isTrue);
    });

    test('캐시 히트 — 두 번째 호출 시 HTTP 요청 없음', () async {
      int requestCount = 0;
      mockClient = MockClient((req) async {
        requestCount++;
        return _utf8Response(_timetableResponse(), 200);
      });
      TimetableDataApi.client = mockClient;

      await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
        grade: '1',
      );
      final second = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 5),
        grade: '1',
      );

      expect(second.containsKey('error'), isFalse);
      expect(requestCount, 1);
    });

    test('classNum 필터링 — URL에 CLASS_NM 포함', () async {
      mockClient = MockClient((req) async {
        expect(req.url.toString(), contains('CLASS_NM=3'));
        return _utf8Response(_timetableResponse(), 200);
      });
      TimetableDataApi.client = mockClient;

      await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 6),
        endDate: DateTime(2026, 4, 10),
        grade: '1',
        classNum: '3',
      );
    });
  });

  group('TimetableDataApi._processTimetable', () {
    test('교시 빈칸 채움 — 3교시만 있으면 1~2교시 빈 문자열', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
            {
              'ALL_TI_YMD': '20260401',
              'CLASS_NM': '1',
              'PERIO': '3',
              'ITRT_CNTNT': '체육',
            },
          ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 4, 1),
        endDate: DateTime(2026, 4, 1),
        grade: '1',
      );

      final periods = result['20260401']!['1']!;
      expect(periods.length, 3);
      expect(periods[0], '');
      expect(periods[1], '');
      expect(periods[2], '체육');
    });
  });

  group('TimetableDataApi.getClassCount', () {
    test('반 수 정상 반환', () async {
      mockClient = MockClient((req) async {
        return _utf8Response({
            'classInfo': [
              {
                'head': [
                  {'list_total_count': 8}
                ]
              },
              {'row': []}
            ]
          }, 200);
      });
      TimetableDataApi.client = mockClient;

      final count = await TimetableDataApi.getClassCount(1);
      expect(count, 8);
    });

    test('데이터 없음 → 0', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_emptyResponse(), 200);
      });
      TimetableDataApi.client = mockClient;

      final count = await TimetableDataApi.getClassCount(1);
      expect(count, 0);
    });
  });

  group('TimetableDataApi.getSubjects', () {
    test('과목 목록 추출 및 정렬', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '1', 'ITRT_CNTNT': '수학'},
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '2', 'ITRT_CNTNT': '국어'},
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '2', 'PERIO': '1', 'ITRT_CNTNT': '영어'},
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '3', 'ITRT_CNTNT': '수학'},
          ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getSubjects(grade: 1);
      expect(subjects, isNotNull);
      expect(subjects!.contains('국어'), isTrue);
      expect(subjects.contains('수학'), isTrue);
      expect(subjects.contains('영어'), isTrue);
      // 중복 제거 확인
      expect(subjects.where((s) => s == '수학').length, 1);
      // 정렬 확인
      expect(subjects, orderedEquals([...subjects]..sort()));
    });

    test('토요휴업일·[보강] 필터링', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '1', 'ITRT_CNTNT': '국어'},
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '2', 'ITRT_CNTNT': '토요휴업일'},
            {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '3', 'ITRT_CNTNT': '[보강]수학'},
          ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getSubjects(grade: 1);
      expect(subjects, isNotNull);
      expect(subjects!.contains('국어'), isTrue);
      expect(subjects.contains('토요휴업일'), isFalse);
      expect(subjects.any((s) => s.contains('[보강]')), isFalse);
    });
  });

  group('TimetableDataApi.getTimeTable SWR 캐시', () {
    test('stale 캐시 (12h~3d) → 즉시 반환', () async {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '20260501-20260505-2';
      final staleData = {
        '20260501': {
          '1': ['stale-math']
        }
      };
      prefs.setString(cacheKey, jsonEncode(staleData));
      // 18시간 전 타임스탬프 (12h < 18h < 3d → stale)
      prefs.setInt(
        '$cacheKey-timestamp',
        DateTime.now().millisecondsSinceEpoch - 18 * 60 * 60 * 1000,
      );

      mockClient = MockClient((req) async {
        fail('stale 캐시는 HTTP 요청 없이 반환해야 함');
        return _utf8Response({}, 200);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 5),
        grade: '2',
      );

      expect(result.containsKey('error'), isFalse);
      expect(result['20260501']!['1']![0], 'stale-math');
    });

    test('만료 캐시 (>3d) → 삭제 후 재요청', () async {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '20260601-20260605-2';
      final expiredData = {
        '20260601': {
          '1': ['expired']
        }
      };
      prefs.setString(cacheKey, jsonEncode(expiredData));
      // 4일 전 (> 3d → 만료)
      prefs.setInt(
        '$cacheKey-timestamp',
        DateTime.now().millisecondsSinceEpoch - 4 * 24 * 60 * 60 * 1000,
      );

      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
          {'ALL_TI_YMD': '20260601', 'CLASS_NM': '1', 'PERIO': '1', 'ITRT_CNTNT': 'fresh'},
        ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 5),
        grade: '2',
      );

      expect(result.containsKey('error'), isFalse);
      expect(result['20260601']!['1']![0], 'fresh');
    });
  });

  group('TimetableDataApi.getTimeTable 네트워크', () {
    test('오프라인 → timetableNoInternet 에러', () async {
      NetworkStatus.testOverride = () async => true; // offline
      mockClient = MockClient((req) async {
        fail('오프라인에서 HTTP 요청하면 안 됨');
        return _utf8Response({}, 200);
      });
      TimetableDataApi.client = mockClient;

      final result = await TimetableDataApi.getTimeTable(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 5),
        grade: '1',
      );

      expect(result.containsKey('error'), isTrue);
      expect(result['error']!['error']!.first, ApiStrings.timetableNoInternet);
    });
  });

  group('TimetableDataApi.getClassCount 캐시', () {
    test('캐시 히트 — 1주일 이내', () async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('classCount-2', 10);
      prefs.setInt(
        'classCount-2-timestamp',
        DateTime.now().millisecondsSinceEpoch - 1000, // 1초 전
      );

      mockClient = MockClient((req) async {
        fail('캐시 히트 시 HTTP 요청 없어야 함');
        return _utf8Response({}, 200);
      });
      TimetableDataApi.client = mockClient;

      final count = await TimetableDataApi.getClassCount(2);
      expect(count, 10);
    });
  });

  group('TimetableDataApi.getAllSubjectCombinations', () {
    test('과목+반 조합 추출 및 캐싱', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '1', 'ITRT_CNTNT': 'Math'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '2', 'PERIO': '1', 'ITRT_CNTNT': 'English'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': 'special', 'PERIO': '1', 'ITRT_CNTNT': 'Music'},
        ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getAllSubjectCombinations(grade: 1);
      expect(subjects, isNotEmpty);

      final names = subjects.map((s) => s.subjectName).toList();
      expect(names, contains('Math'));
      expect(names, contains('English'));
      expect(names, contains('Music'));

      // special 반 → subjectClass -1
      final music = subjects.firstWhere((s) => s.subjectName == 'Music');
      expect(music.subjectClass, -1);

      // 캐싱 확인
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('subjects_grade_1'), isTrue);
    });

    test('캐시 히트 → HTTP 요청 없음', () async {
      final prefs = await SharedPreferences.getInstance();
      final cached = [
        {'subjectName': 'CachedSubject', 'subjectClass': 1},
      ];
      prefs.setString('subjects_grade_3', jsonEncode(cached));
      prefs.setInt(
        'subjects_grade_3_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      mockClient = MockClient((req) async {
        fail('캐시 히트 시 HTTP 요청 없어야 함');
        return _utf8Response({}, 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getAllSubjectCombinations(grade: 3);
      expect(subjects.length, 1);
      expect(subjects.first.subjectName, 'CachedSubject');
    });

    test('[보강]·토요휴업일 필터링', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '1', 'ITRT_CNTNT': 'OK'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '2', 'ITRT_CNTNT': '[보강]Bad'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '3', 'ITRT_CNTNT': '토요휴업일'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '4', 'ITRT_CNTNT': ''},
        ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getAllSubjectCombinations(grade: 2);
      final names = subjects.map((s) => s.subjectName).toList();
      expect(names, contains('OK'));
      expect(names.any((n) => n.contains('[보강]')), isFalse);
      expect(names, isNot(contains('토요휴업일')));
      expect(names, isNot(contains('')));
    });

    test('이름+반으로 정렬', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(rows: [
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '2', 'PERIO': '1', 'ITRT_CNTNT': 'B'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '1', 'ITRT_CNTNT': 'A'},
          {'ALL_TI_YMD': '20260401', 'CLASS_NM': '1', 'PERIO': '2', 'ITRT_CNTNT': 'B'},
        ]), 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getAllSubjectCombinations(grade: 1);
      // A(1), B(1), B(2) 순서
      expect(subjects[0].subjectName, 'A');
      expect(subjects[1].subjectName, 'B');
      expect(subjects[1].subjectClass, 1);
      if (subjects.length > 2) {
        expect(subjects[2].subjectName, 'B');
        expect(subjects[2].subjectClass, 2);
      }
    });
  });

  group('TimetableDataApi.getCustomTimeTable', () {
    test('빈 과목 리스트 → 빈 시간표', () async {
      mockClient = MockClient((req) async {
        return _utf8Response(_timetableResponse(), 200);
      });
      TimetableDataApi.client = mockClient;

      final table = await TimetableDataApi.getCustomTimeTable(
        userSubjects: [],
        grade: '3',
      );

      expect(table.length, 6);
      for (int i = 1; i < 6; i++) {
        for (int j = 1; j < table[i].length; j++) {
          expect(table[i][j], '');
        }
      }
    });
  });

  group('TimetableDataApi.getSubjects 캐시', () {
    test('캐시 히트 → HTTP 요청 없음', () async {
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('subjects-2', jsonEncode(['Art', 'Music', 'PE']));
      prefs.setInt(
        'subjects-2-timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      mockClient = MockClient((req) async {
        fail('캐시 히트 시 HTTP 요청 없어야 함');
        return _utf8Response({}, 200);
      });
      TimetableDataApi.client = mockClient;

      final subjects = await TimetableDataApi.getSubjects(grade: 2);
      expect(subjects, ['Art', 'Music', 'PE']);
    });
  });
}
