import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// `flutter_secure_storage` wrapper
///
/// - 민감한 개인정보(성적, 디데이 등)를 Android Keystore / iOS Keychain에 저장
/// - 키 상수는 이 클래스에 모아서 오타/중복 방지
/// - 모든 메서드는 silent fail (로깅만), 호출부는 fallback 처리
///
/// **저장 정책:**
/// - **여기에 저장**: 학업 기록(성적, 목표), D-day 등 개인 식별 가능 정보
/// - **여기에 저장하지 않음**: 캐시(시간표/급식/공지) — 빠른 read 우선, 평문 OK
/// - **자동 관리(저장 불필요)**: Firebase Auth / Kakao SDK 토큰 — SDK가 안전 저장소 자체 관리
class SecureStorageService {
  SecureStorageService._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // 키 상수 (네임스페이스 prefix로 충돌 방지)
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

  /// SharedPreferences → SecureStorage 일회성 마이그레이션 helper
  ///
  /// - `oldValue`가 있고 secure storage가 비어있으면 옮김
  /// - 마이그레이션 후 `onMigrated` 콜백으로 SharedPreferences에서 삭제하도록 호출부에 위임
  /// - 반환: 옮겨진 경우 true, 이미 있거나 옮길 게 없으면 false
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
