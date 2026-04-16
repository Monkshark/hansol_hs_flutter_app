import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/input_sanitizer.dart';

void main() {
  test('strips HTML tags', () {
    expect(InputSanitizer.sanitize('<b>bold</b>'), 'bold');
  });
  test('strips script tags with content', () {
    expect(InputSanitizer.sanitize('hello<script>alert("xss")</script>world'), 'helloworld');
  });
  test('normalizes excessive newlines', () {
    expect(InputSanitizer.sanitize('a\n\n\n\n\nb'), 'a\n\n\nb');
  });
  test('preserves normal text', () {
    expect(InputSanitizer.sanitize('안녕하세요 반갑습니다'), '안녕하세요 반갑습니다');
  });
  test('trims whitespace', () {
    expect(InputSanitizer.sanitize('  hello  '), 'hello');
  });
}
