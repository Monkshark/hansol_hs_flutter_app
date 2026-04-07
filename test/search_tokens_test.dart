import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/search_tokens.dart';

void main() {
  group('SearchTokens.forDocument', () {
    test('한글 2-gram 생성', () {
      final tokens = SearchTokens.forDocument('기말고사', '');
      expect(tokens, containsAll(['기말', '말고', '고사']));
    });

    test('제목+본문 결합 토큰화', () {
      final tokens = SearchTokens.forDocument('수학', '시험');
      expect(tokens, contains('수학'));
      expect(tokens, contains('시험'));
    });

    test('영문은 lowercase', () {
      final tokens = SearchTokens.forDocument('Math', '');
      expect(tokens, contains('ma'));
      expect(tokens, contains('at'));
      expect(tokens, contains('th'));
    });

    test('공백/기호는 제거', () {
      final tokens = SearchTokens.forDocument('A B!', '');
      expect(tokens, contains('ab'));
    });

    test('중복 제거', () {
      final tokens = SearchTokens.forDocument('가가가', '');
      expect(tokens.where((t) => t == '가가').length, 1);
    });

    test('maxTokens 제한', () {
      const long = '가나다라마바사아자차카타파하';
      final tokens = SearchTokens.forDocument(long, '', maxTokens: 5);
      expect(tokens.length, lessThanOrEqualTo(5));
    });
  });

  group('SearchTokens.forQuery', () {
    test('빈 query는 빈 리스트', () {
      expect(SearchTokens.forQuery(''), isEmpty);
      expect(SearchTokens.forQuery('   '), isEmpty);
    });

    test('1글자 query는 1-gram 단일 반환', () {
      expect(SearchTokens.forQuery('가'), ['가']);
    });

    test('2글자 이상은 2-gram', () {
      final t = SearchTokens.forQuery('수학시험');
      expect(t, containsAll(['수학', '학시', '시험']));
    });

    test('forQuery는 maxTokens=10', () {
      final t = SearchTokens.forQuery('가나다라마바사아자차카타파하');
      expect(t.length, lessThanOrEqualTo(10));
    });
  });
}
