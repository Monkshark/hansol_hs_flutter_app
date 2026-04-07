import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hansol_high_school/data/search_history_service.dart';

/// SearchHistoryService 단위 테스트
///
/// SharedPreferences mock으로 로컬 저장소 흐름만 검증.
/// (FIFO + dedupe + 10개 cap + 빈 문자열 무시 + load 파싱 안전성)
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('초기 상태: load는 빈 리스트', () async {
    expect(await SearchHistoryService.load(), isEmpty);
  });

  test('add: 최신 검색어가 맨 앞에 삽입', () async {
    await SearchHistoryService.add('시험');
    await SearchHistoryService.add('급식');
    await SearchHistoryService.add('동아리');

    final list = await SearchHistoryService.load();
    expect(list, ['동아리', '급식', '시험']);
  });

  test('add: 같은 검색어 재입력 시 dedupe + 맨 앞으로 이동', () async {
    await SearchHistoryService.add('시험');
    await SearchHistoryService.add('급식');
    await SearchHistoryService.add('시험');

    final list = await SearchHistoryService.load();
    expect(list, ['시험', '급식']);
    expect(list.length, 2);
  });

  test('add: 양옆 공백은 trim, 빈 문자열은 무시', () async {
    await SearchHistoryService.add('  시험  ');
    await SearchHistoryService.add('');
    await SearchHistoryService.add('   ');

    final list = await SearchHistoryService.load();
    expect(list, ['시험']);
  });

  test('add: 11개째 입력 시 가장 오래된 항목 drop (max 10)', () async {
    for (int i = 1; i <= 11; i++) {
      await SearchHistoryService.add('q$i');
    }

    final list = await SearchHistoryService.load();
    expect(list.length, 10);
    // 최신부터 정렬: q11 ~ q2 (q1 drop)
    expect(list.first, 'q11');
    expect(list.last, 'q2');
    expect(list.contains('q1'), isFalse);
  });

  test('remove: 특정 검색어만 삭제', () async {
    await SearchHistoryService.add('시험');
    await SearchHistoryService.add('급식');
    await SearchHistoryService.add('동아리');

    await SearchHistoryService.remove('급식');

    final list = await SearchHistoryService.load();
    expect(list, ['동아리', '시험']);
  });

  test('clear: 전체 삭제', () async {
    await SearchHistoryService.add('시험');
    await SearchHistoryService.add('급식');
    await SearchHistoryService.clear();

    expect(await SearchHistoryService.load(), isEmpty);
  });

  test('load: 손상된 JSON이 들어있어도 빈 리스트 반환 (crash 안 남)', () async {
    SharedPreferences.setMockInitialValues({
      'board_search_history': '{not valid json',
    });
    expect(await SearchHistoryService.load(), isEmpty);
  });

  test('load: List가 아닌 JSON이면 빈 리스트', () async {
    SharedPreferences.setMockInitialValues({
      'board_search_history': jsonEncode({'foo': 'bar'}),
    });
    expect(await SearchHistoryService.load(), isEmpty);
  });

  test('load: List 안에 String이 아닌 항목 섞여있으면 String만 추출', () async {
    SharedPreferences.setMockInitialValues({
      'board_search_history': jsonEncode(['시험', 123, null, '급식']),
    });
    final list = await SearchHistoryService.load();
    expect(list, ['시험', '급식']);
  });
}
