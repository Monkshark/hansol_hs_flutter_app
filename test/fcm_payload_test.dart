import 'package:flutter_test/flutter_test.dart';

/// FcmService._encodePayload 순수 로직 복제
String encodePayload(Map<String, dynamic> data) {
  return data.entries.map((e) => '${e.key}=${e.value}').join(';');
}

/// FcmService.decodePayload 순수 로직 복제
Map<String, dynamic> decodePayload(String payload) {
  final map = <String, dynamic>{};
  for (final pair in payload.split(';')) {
    final idx = pair.indexOf('=');
    if (idx > 0) {
      map[pair.substring(0, idx)] = pair.substring(idx + 1);
    }
  }
  return map;
}

void main() {
  group('encodePayload', () {
    test('encodes single entry', () {
      expect(encodePayload({'type': 'comment'}), 'type=comment');
    });

    test('encodes multiple entries', () {
      final result = encodePayload({'type': 'comment', 'postId': 'abc123'});
      expect(result, contains('type=comment'));
      expect(result, contains('postId=abc123'));
      expect(result.split(';').length, 2);
    });

    test('encodes empty map', () {
      expect(encodePayload({}), '');
    });
  });

  group('decodePayload', () {
    test('decodes single entry', () {
      final result = decodePayload('type=comment');
      expect(result['type'], 'comment');
    });

    test('decodes multiple entries', () {
      final result = decodePayload('type=comment;postId=abc123');
      expect(result['type'], 'comment');
      expect(result['postId'], 'abc123');
    });

    test('handles empty string', () {
      expect(decodePayload(''), isEmpty);
    });

    test('handles value containing =', () {
      final result = decodePayload('key=val=ue');
      expect(result['key'], 'val=ue');
    });

    test('ignores malformed entries', () {
      final result = decodePayload('good=val;bad;also=ok');
      expect(result.length, 2);
      expect(result['good'], 'val');
      expect(result['also'], 'ok');
    });
  });

  group('encode/decode roundtrip', () {
    test('roundtrip preserves data', () {
      final original = {'type': 'new_post', 'postId': 'p123', 'category': 'free'};
      final encoded = encodePayload(original);
      final decoded = decodePayload(encoded);
      expect(decoded['type'], 'new_post');
      expect(decoded['postId'], 'p123');
      expect(decoded['category'], 'free');
    });
  });

  group('FcmService topic names', () {
    // _categoryTopicKey + _topicName 로직 복제
    String topicName(String category) {
      const categoryTopicKey = {
        '자유': 'free',
        '질문': 'question',
        '정보공유': 'info',
        '분실물': 'lost',
        '학생회': 'council',
        '동아리': 'club',
      };
      return 'board_${categoryTopicKey[category] ?? category}';
    }

    test('known categories map correctly', () {
      expect(topicName('자유'), 'board_free');
      expect(topicName('질문'), 'board_question');
      expect(topicName('정보공유'), 'board_info');
      expect(topicName('분실물'), 'board_lost');
      expect(topicName('학생회'), 'board_council');
      expect(topicName('동아리'), 'board_club');
    });

    test('unknown category uses raw name', () {
      expect(topicName('custom'), 'board_custom');
    });
  });
}
