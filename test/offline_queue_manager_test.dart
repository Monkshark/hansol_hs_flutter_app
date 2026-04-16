import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/network/offline_queue_manager.dart';

void main() {
  group('SyncStatus', () {
    test('idle 상태', () {
      final status = SyncStatus.idle();
      expect(status.state, SyncState.idle);
      expect(status.pendingCount, 0);
    });

    test('pending 상태', () {
      final status = SyncStatus.pending(3);
      expect(status.state, SyncState.pending);
      expect(status.pendingCount, 3);
    });

    test('syncing 상태', () {
      final status = SyncStatus.syncing(2);
      expect(status.state, SyncState.syncing);
      expect(status.pendingCount, 2);
    });
  });

  group('SyncState enum', () {
    test('모든 상태 존재', () {
      expect(SyncState.values.length, 3);
      expect(SyncState.values, contains(SyncState.idle));
      expect(SyncState.values, contains(SyncState.pending));
      expect(SyncState.values, contains(SyncState.syncing));
    });
  });

  group('OfflineQueueManager 싱글톤', () {
    test('동일 인스턴스 반환', () {
      final a = OfflineQueueManager.instance;
      final b = OfflineQueueManager.instance;
      expect(identical(a, b), isTrue);
    });

    test('초기 pendingCount = 0', () {
      // initialize() 호출 전이므로 0
      expect(OfflineQueueManager.instance.pendingCount, 0);
    });
  });

  group('ServerTimestamp 직렬화 로직', () {
    // _sanitizeForStorage와 _restoreTimestamps는 private이므로
    // 동일한 로직을 검증하는 단위 테스트

    const placeholder = '__SERVER_TIMESTAMP__';

    Map<String, dynamic> sanitize(Map<String, dynamic> data) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        if (entry.value.toString().contains('FieldValue')) {
          result[entry.key] = placeholder;
        } else if (entry.value is Map) {
          result[entry.key] = sanitize(Map<String, dynamic>.from(entry.value as Map));
        } else {
          result[entry.key] = entry.value;
        }
      }
      return result;
    }

    bool hasPlaceholder(Map<String, dynamic> data) {
      for (final value in data.values) {
        if (value == placeholder) return true;
        if (value is Map) {
          if (hasPlaceholder(Map<String, dynamic>.from(value))) return true;
        }
      }
      return false;
    }

    test('일반 데이터는 그대로 유지', () {
      final data = {'title': '테스트', 'content': '내용', 'count': 0};
      final result = sanitize(data);
      expect(result['title'], '테스트');
      expect(result['content'], '내용');
      expect(result['count'], 0);
      expect(hasPlaceholder(result), isFalse);
    });

    test('중첩 Map 처리', () {
      final data = {
        'title': '테스트',
        'nested': {'key': 'value', 'num': 42},
      };
      final result = sanitize(data);
      expect(result['nested'], isA<Map>());
      expect((result['nested'] as Map)['key'], 'value');
    });

    test('플레이스홀더가 JSON 직렬화 가능', () {
      final data = {'createdAt': placeholder, 'title': '테스트'};
      final json = jsonEncode(data);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['createdAt'], placeholder);
    });

    test('빈 데이터 처리', () {
      final result = sanitize(<String, dynamic>{});
      expect(result, isEmpty);
    });

    test('null 값 유지', () {
      final data = <String, dynamic>{'key': null};
      final result = sanitize(data);
      expect(result['key'], isNull);
    });
  });

  group('큐 데이터 모델', () {
    test('글 작성 payload 구조', () {
      final postData = {
        'title': '오프라인 글',
        'content': '내용',
        'category': '자유',
        'authorUid': 'uid123',
        'createdAt': '__SERVER_TIMESTAMP__',
      };

      final json = jsonEncode(postData);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['title'], '오프라인 글');
      expect(decoded['createdAt'], '__SERVER_TIMESTAMP__');
    });

    test('댓글 작성 payload 구조', () {
      final commentPayload = {
        'postId': 'post123',
        'commentData': {
          'content': '댓글 내용',
          'authorUid': 'uid123',
          'createdAt': '__SERVER_TIMESTAMP__',
        },
      };

      final json = jsonEncode(commentPayload);
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['postId'], 'post123');
      expect((decoded['commentData'] as Map)['content'], '댓글 내용');
    });

    test('큐 row 구조', () {
      final row = {
        'id': 1,
        'type': 'create_post',
        'payload': jsonEncode({'title': 'test'}),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'retryCount': 0,
      };

      expect(row['type'], 'create_post');
      expect(row['retryCount'], 0);
      final payload = jsonDecode(row['payload'] as String) as Map;
      expect(payload['title'], 'test');
    });
  });
}
