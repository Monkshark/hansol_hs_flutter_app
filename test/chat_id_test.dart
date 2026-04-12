import 'package:flutter_test/flutter_test.dart';

/// chat_utils._getChatId 순수 로직 복제
String getChatId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return '${sorted[0]}_${sorted[1]}';
}

void main() {
  group('getChatId', () {
    test('creates consistent id regardless of order', () {
      expect(getChatId('alice', 'bob'), getChatId('bob', 'alice'));
    });

    test('sorts alphabetically', () {
      expect(getChatId('bob', 'alice'), 'alice_bob');
    });

    test('same uid twice', () {
      expect(getChatId('uid1', 'uid1'), 'uid1_uid1');
    });

    test('uses underscore separator', () {
      final id = getChatId('abc', 'def');
      expect(id, 'abc_def');
      expect(id.split('_').length, 2);
    });

    test('handles uid with numbers', () {
      expect(getChatId('user123', 'admin001'), 'admin001_user123');
    });
  });
}
