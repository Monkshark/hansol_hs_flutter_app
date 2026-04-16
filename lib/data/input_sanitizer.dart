class InputSanitizer {
  static final _htmlTagPattern = RegExp(r'<[^>]*>', multiLine: true);
  static final _scriptPattern = RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false, multiLine: true);
  static final _excessiveWhitespace = RegExp(r'\n{4,}');

  /// Sanitize user input: strip HTML/script tags, normalize whitespace
  static String sanitize(String input) {
    var result = input;
    result = result.replaceAll(_scriptPattern, '');
    result = result.replaceAll(_htmlTagPattern, '');
    result = result.replaceAll(_excessiveWhitespace, '\n\n\n');
    return result.trim();
  }
}
