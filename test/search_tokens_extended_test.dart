import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/search_tokens.dart';

void main() {
  group('SearchTokens.forDocument', () {
    test('generates 2-grams from title and content', () {
      final tokens = SearchTokens.forDocument('안녕', '세상');
      expect(tokens, contains('안녕'));
      expect(tokens, contains('녕세'));
      expect(tokens, contains('세상'));
    });

    test('removes special characters', () {
      final tokens = SearchTokens.forDocument('안녕!', '세상@#');
      expect(tokens.any((t) => t.contains('!')), false);
      expect(tokens.any((t) => t.contains('@')), false);
    });

    test('lowercases English', () {
      final tokens = SearchTokens.forDocument('Hello', '');
      expect(tokens, contains('he'));
      expect(tokens, contains('el'));
      expect(tokens, contains('ll'));
      expect(tokens, contains('lo'));
    });

    test('includes Korean characters', () {
      final tokens = SearchTokens.forDocument('급식메뉴', '');
      expect(tokens, contains('급식'));
      expect(tokens, contains('식메'));
      expect(tokens, contains('메뉴'));
    });

    test('includes numbers', () {
      final tokens = SearchTokens.forDocument('2학년', '');
      expect(tokens, contains('2학'));
      expect(tokens, contains('학년'));
    });

    test('respects maxTokens limit', () {
      final longText = '가나다라마바사아자차카타파하' * 20;
      final tokens = SearchTokens.forDocument(longText, '', maxTokens: 50);
      expect(tokens.length, lessThanOrEqualTo(50));
    });

    test('empty title and content returns empty', () {
      final tokens = SearchTokens.forDocument('', '');
      expect(tokens, isEmpty);
    });

    test('single character title with content', () {
      final tokens = SearchTokens.forDocument('가', '나다');
      expect(tokens, contains('가나'));
      expect(tokens, contains('나다'));
    });

    test('deduplicates identical 2-grams', () {
      final tokens = SearchTokens.forDocument('가나가나', '');
      final uniqueCount = tokens.toSet().length;
      expect(tokens.length, uniqueCount);
    });
  });

  group('SearchTokens.forQuery', () {
    test('generates tokens from query', () {
      final tokens = SearchTokens.forQuery('급식');
      expect(tokens, contains('급식'));
    });

    test('single character returns as-is', () {
      final tokens = SearchTokens.forQuery('가');
      expect(tokens, ['가']);
    });

    test('empty query returns empty', () {
      expect(SearchTokens.forQuery(''), isEmpty);
    });

    test('special chars only returns empty', () {
      expect(SearchTokens.forQuery('!@#\$%'), isEmpty);
    });

    test('respects maxTokens', () {
      final tokens = SearchTokens.forQuery('가나다라마바사아자차카타파하', maxTokens: 3);
      expect(tokens.length, lessThanOrEqualTo(3));
    });

    test('mixed Korean and English', () {
      final tokens = SearchTokens.forQuery('flutter앱');
      expect(tokens, contains('er'));
      expect(tokens, contains('r앱'));
    });
  });
}
