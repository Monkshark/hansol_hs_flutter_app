import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/secure_storage_service.dart';

import 'helpers/secure_storage_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final secureStore = setupSecureStorageMock();

  setUp(() => secureStore.clear());

  group('SecureStorageService', () {
    test('write/read round-trip', () async {
      await SecureStorageService.write('test_key', 'hello');
      expect(await SecureStorageService.read('test_key'), 'hello');
    });

    test('read 빈 키 → null 반환', () async {
      expect(await SecureStorageService.read('nonexistent'), isNull);
    });

    test('delete → 키 제거', () async {
      await SecureStorageService.write('k', 'v');
      await SecureStorageService.delete('k');
      expect(await SecureStorageService.read('k'), isNull);
    });

    test('deleteAll → 모든 키 제거', () async {
      await SecureStorageService.write('a', '1');
      await SecureStorageService.write('b', '2');
      await SecureStorageService.deleteAll();
      expect(await SecureStorageService.read('a'), isNull);
      expect(await SecureStorageService.read('b'), isNull);
    });
  });

  group('SecureStorageService.migrateFromPlain', () {
    test('oldValue가 null이면 false 반환 + onMigrated 호출 안 됨', () async {
      var migrated = false;
      final result = await SecureStorageService.migrateFromPlain(
        key: 'k',
        oldValue: null,
        onMigrated: () async => migrated = true,
      );
      expect(result, isFalse);
      expect(migrated, isFalse);
    });

    test('oldValue가 빈 문자열이면 false 반환', () async {
      final result = await SecureStorageService.migrateFromPlain(
        key: 'k',
        oldValue: '',
        onMigrated: () async {},
      );
      expect(result, isFalse);
    });

    test('이미 secure에 값이 있으면 덮어쓰지 않음', () async {
      await SecureStorageService.write('k', 'existing');
      final result = await SecureStorageService.migrateFromPlain(
        key: 'k',
        oldValue: 'plain',
        onMigrated: () async {},
      );
      expect(result, isFalse);
      expect(await SecureStorageService.read('k'), 'existing');
    });

    test('정상 마이그레이션 → secure에 저장 + onMigrated 호출', () async {
      var migrated = false;
      final result = await SecureStorageService.migrateFromPlain(
        key: 'k',
        oldValue: 'plain_value',
        onMigrated: () async => migrated = true,
      );
      expect(result, isTrue);
      expect(migrated, isTrue);
      expect(await SecureStorageService.read('k'), 'plain_value');
    });
  });
}
