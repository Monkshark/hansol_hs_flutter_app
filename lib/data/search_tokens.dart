class SearchTokens {
  static List<String> forDocument(String title, String content, {int maxTokens = 200}) {
    final combined = '$title $content';
    final tokens = _ngrams(combined);
    if (tokens.length <= maxTokens) return tokens.toList();
    return tokens.take(maxTokens).toList();
  }

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

  static String _normalize(String text) {
    final lower = text.toLowerCase();
    final buf = StringBuffer();
    for (final r in lower.runes) {
      if (r >= 0x30 && r <= 0x39) {
        buf.writeCharCode(r);
        continue;
      }
      if (r >= 0x61 && r <= 0x7A) {
        buf.writeCharCode(r);
        continue;
      }
      if (r >= 0xAC00 && r <= 0xD7A3) {
        buf.writeCharCode(r);
        continue;
      }
    }
    return buf.toString();
  }
}
