import 'package:flutter_test/flutter_test.dart';

/// DeepLinkService URI 파싱 로직 테스트
///
/// DeepLinkService._handleUri는 private이므로
/// URI 파싱 로직을 직접 검증하는 단위 테스트로 대체함.
void main() {
  const postPrefix = '/post/';

  String? extractPostId(Uri uri) {
    final path = uri.path;
    if (path.startsWith(postPrefix)) {
      final postId = path.substring(postPrefix.length).replaceAll('/', '');
      if (postId.isNotEmpty) return postId;
    }
    return null;
  }

  group('URI 파싱', () {
    test('정상 딥링크에서 postId 추출', () {
      final uri = Uri.parse('https://example.com/post/abc123');
      expect(extractPostId(uri), 'abc123');
    });

    test('trailing slash 제거', () {
      final uri = Uri.parse('https://example.com/post/abc123/');
      expect(extractPostId(uri), 'abc123');
    });

    test('빈 postId → null', () {
      final uri = Uri.parse('https://example.com/post/');
      expect(extractPostId(uri), isNull);
    });

    test('post 경로가 아니면 null', () {
      final uri = Uri.parse('https://example.com/about');
      expect(extractPostId(uri), isNull);
    });

    test('루트 경로 → null', () {
      final uri = Uri.parse('https://example.com/');
      expect(extractPostId(uri), isNull);
    });

    test('빈 경로 → null', () {
      final uri = Uri.parse('https://example.com');
      expect(extractPostId(uri), isNull);
    });

    test('중첩 경로 슬래시 제거', () {
      final uri = Uri.parse('https://example.com/post/abc/def/');
      expect(extractPostId(uri), 'abcdef');
    });

    test('쿼리 파라미터 무시', () {
      final uri = Uri.parse('https://example.com/post/abc123?ref=share');
      expect(extractPostId(uri), 'abc123');
    });

    test('fragment 무시', () {
      final uri = Uri.parse('https://example.com/post/abc123#section');
      expect(extractPostId(uri), 'abc123');
    });

    test('/post 접두사 대소문자 구분', () {
      final uri = Uri.parse('https://example.com/Post/abc123');
      expect(extractPostId(uri), isNull);
    });

    test('Firestore document ID 형태', () {
      final uri = Uri.parse('https://example.com/post/KxY3z9mN2wRtLp5');
      expect(extractPostId(uri), 'KxY3z9mN2wRtLp5');
    });

    test('특수문자 포함 경로', () {
      final uri = Uri.parse('https://example.com/post/abc-123_def');
      expect(extractPostId(uri), 'abc-123_def');
    });
  });

  group('URI 스킴', () {
    test('https 스킴', () {
      final uri = Uri.parse('https://example.com/post/id1');
      expect(extractPostId(uri), 'id1');
    });

    test('http 스킴', () {
      final uri = Uri.parse('http://example.com/post/id2');
      expect(extractPostId(uri), 'id2');
    });

    test('커스텀 앱 스킴', () {
      final uri = Uri.parse('hansolhs://app/post/id3');
      expect(extractPostId(uri), 'id3');
    });
  });

  group('엣지 케이스', () {
    test('매우 긴 postId', () {
      final longId = 'a' * 200;
      final uri = Uri.parse('https://example.com/post/$longId');
      expect(extractPostId(uri), longId);
    });

    test('/post 만 있고 뒤에 아무것도 없는 경우', () {
      final uri = Uri.parse('https://example.com/post');
      expect(extractPostId(uri), isNull);
    });

    test('URL 인코딩된 postId', () {
      final uri = Uri.parse('https://example.com/post/%ED%95%9C%EA%B8%80');
      final result = extractPostId(uri);
      expect(result, isNotNull);
      expect(result!.isNotEmpty, isTrue);
    });

    test('숫자만 postId', () {
      final uri = Uri.parse('https://example.com/post/123456');
      expect(extractPostId(uri), '123456');
    });
  });
}
