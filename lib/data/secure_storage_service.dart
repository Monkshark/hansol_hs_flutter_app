import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String keyGradeExams = 'secure_grade_exams';
  static const String keyGradeGoals = 'secure_grade_goals';
  static const String keyGradeJeongsiGoals = 'secure_grade_jeongsi_goals';
  static const String keyDdays = 'secure_ddays';

  static Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      log('SecureStorage read failed for $key: $e', name: 'SecureStorage');
      return null;
    }
  }

  static Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      log('SecureStorage write failed for $key: $e', name: 'SecureStorage');
    }
  }

  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      log('SecureStorage delete failed for $key: $e', name: 'SecureStorage');
    }
  }

  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      log('SecureStorage deleteAll failed: $e', name: 'SecureStorage');
    }
  }

  static Future<bool> migrateFromPlain({
    required String key,
    required String? oldValue,
    required Future<void> Function() onMigrated,
  }) async {
    if (oldValue == null || oldValue.isEmpty) return false;
    final existing = await read(key);
    if (existing != null && existing.isNotEmpty) return false;
    await write(key, oldValue);
    await onMigrated();
    log('SecureStorage migrated $key from plain', name: 'SecureStorage');
    return true;
  }
}
