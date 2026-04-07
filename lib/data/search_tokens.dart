/// 한국어 게시글 검색을 위한 n-gram 토크나이저
///
/// Firestore는 LIKE/full-text 검색이 없어서, 글 작성 시 미리
/// 제목+본문을 2-gram으로 분해해 `searchTokens` 배열에 저장하고,
/// 검색 시 [tokenizeQuery]로 동일하게 분해해 `array-contains-any`
/// 쿼리로 매칭한다.
///
/// 예) "기말고사 일정" → ['기말','말고','고사','일정']
///
/// 한국어는 단어 구분이 모호해 단어 단위 인덱싱은 부적합하므로
/// 2-gram 방식이 정확도/저장 비용 절충점.
class SearchTokens {
  /// 글 저장 시 사용. 제목+본문 합쳐서 모든 2-gram 생성.
  /// - 영문은 lowercase
  /// - 공백/기호 제거
  /// - 결과는 set으로 dedupe, 최대 [maxTokens]개로 잘라 저장 비용 제한
  static List<String> forDocument(String title, String content, {int maxTokens = 200}) {
    final combined = '$title $content';
    final tokens = _ngrams(combined);
    if (tokens.length <= maxTokens) return tokens.toList();
    return tokens.take(maxTokens).toList();
  }

  /// 검색 시 사용. 사용자 query에서 2-gram 추출.
  /// - 1글자 query는 그대로 1-gram 한 개 (Firestore array-contains-any로는
  ///   substring 매칭 불가하므로 결과 없음 → caller가 fallback 처리)
  /// - 결과는 [maxTokens]개 (Firestore array-contains-any 한계 = 30)
  static List<String> forQuery(String query, {int maxTokens = 10}) {
    final cleaned = _normalize(query);
    if (cleaned.isEmpty) return const [];
    if (cleaned.length == 1) return [cleaned];
    final tokens = _ngrams(query);
    if (tokens.length <= maxTokens) return tokens.toList();
    return tokens.take(maxTokens).toList();
  }

  static Set<String> _ngrams(String text) {
    final cleaned = _normalize(text);
    final out = <String>{};
    for (int i = 0; i + 2 <= cleaned.length; i++) {
      out.add(cleaned.substring(i, i + 2));
    }
    return out;
  }

  /// 소문자화 + 공백/기호 제거. 한글/숫자/영문만 남김.
  static String _normalize(String text) {
    final lower = text.toLowerCase();
    final buf = StringBuffer();
    for (final r in lower.runes) {
      // 0-9
      if (r >= 0x30 && r <= 0x39) {
        buf.writeCharCode(r);
        continue;
      }
      // a-z
      if (r >= 0x61 && r <= 0x7A) {
        buf.writeCharCode(r);
        continue;
      }
      // 한글 음절 (가-힣)
      if (r >= 0xAC00 && r <= 0xD7A3) {
        buf.writeCharCode(r);
        continue;
      }
      // 그 외(공백/기호/한자/이모지 등)는 무시
    }
    return buf.toString();
  }
}
