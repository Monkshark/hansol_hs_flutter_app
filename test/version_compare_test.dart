import 'package:flutter_test/flutter_test.dart';

/// UpdateChecker._compareVersions 순수 로직 복제
int compareVersions(String a, String b) {
  if (a.isEmpty || b.isEmpty) return 0;
  final aParts = a.split('.').map(int.parse).toList();
  final bParts = b.split('.').map(int.parse).toList();
  final len = aParts.length > bParts.length ? aParts.length : bParts.length;

  for (int i = 0; i < len; i++) {
    final av = i < aParts.length ? aParts[i] : 0;
    final bv = i < bParts.length ? bParts[i] : 0;
    if (av < bv) return -1;
    if (av > bv) return 1;
  }
  return 0;
}

void main() {
  group('compareVersions', () {
    test('equal versions return 0', () {
      expect(compareVersions('1.0.0', '1.0.0'), 0);
    });

    test('a < b returns -1', () {
      expect(compareVersions('1.0.0', '1.0.1'), -1);
      expect(compareVersions('1.0.0', '1.1.0'), -1);
      expect(compareVersions('1.0.0', '2.0.0'), -1);
    });

    test('a > b returns 1', () {
      expect(compareVersions('1.0.1', '1.0.0'), 1);
      expect(compareVersions('2.0.0', '1.9.9'), 1);
    });

    test('different length versions', () {
      expect(compareVersions('1.0', '1.0.0'), 0);
      expect(compareVersions('1.0', '1.0.1'), -1);
      expect(compareVersions('1.1', '1.0.9'), 1);
    });

    test('empty string returns 0', () {
      expect(compareVersions('', '1.0.0'), 0);
      expect(compareVersions('1.0.0', ''), 0);
      expect(compareVersions('', ''), 0);
    });

    test('major version difference', () {
      expect(compareVersions('3.0.0', '2.9.9'), 1);
    });

    test('complex versions', () {
      expect(compareVersions('1.2.3', '1.2.4'), -1);
      expect(compareVersions('10.0.0', '9.9.9'), 1);
    });
  });
}
