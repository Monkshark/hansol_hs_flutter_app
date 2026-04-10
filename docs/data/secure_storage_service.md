# SecureStorageService

> `lib/data/secure_storage_service.dart` — 암호화 저장소 래퍼

`flutter_secure_storage` wrapper. 모든 메서드가 `static`. Silent fail (에러 시 로깅만).

---

## 저장 정책

| 여기에 저장 | 여기에 저장하지 않음 |
|-------------|---------------------|
| 학업 기록 (성적, 목표) | 캐시 (시간표/급식/공지) — 빠른 read, 평문 OK |
| D-day 등 개인 식별 정보 | Firebase Auth / Kakao SDK 토큰 — SDK 자체 관리 |

---

## 키 상수

```dart
static const String keyGradeExams = 'secure_grade_exams';
static const String keyGradeGoals = 'secure_grade_goals';
static const String keyGradeJeongsiGoals = 'secure_grade_jeongsi_goals';
static const String keyDdays = 'secure_ddays';
```

네임스페이스 prefix(`secure_`)로 충돌 방지.

---

## 플랫폼 설정

```dart
static const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

- **Android**: `EncryptedSharedPreferences` 사용 (AES-256)
- **iOS**: Keychain, `first_unlock` — 기기 잠금 해제 후 접근 가능

---

## `read`

```dart
static Future<String?> read(String key)
```

키에 해당하는 값을 읽음. 에러 시 null 반환 (로깅만).

---

## `write`

```dart
static Future<void> write(String key, String value)
```

키-값 쌍을 암호화 저장. 에러 시 silent fail.

---

## `delete` / `deleteAll`

```dart
static Future<void> delete(String key)
static Future<void> deleteAll()
```

단일/전체 키 삭제. 에러 시 silent fail.

---

## `migrateFromPlain`

```dart
static Future<bool> migrateFromPlain({
  required String key,
  required String? oldValue,
  required Future<void> Function() onMigrated,
})
```

**설명**: SharedPreferences(평문) → SecureStorage(암호화) 일회성 마이그레이션 helper.

```dart
if (oldValue == null || oldValue.isEmpty) return false;  // 옮길 게 없음
final existing = await read(key);
if (existing != null && existing.isNotEmpty) return false;  // 이미 있음
await write(key, oldValue);      // 암호화 저장
await onMigrated();              // 호출부가 SharedPreferences에서 삭제
```

- `GradeManager.loadExams`, `DDayManager.loadAll` 등에서 첫 호출 시 자동 실행
- 한 번 마이그레이션되면 다시 실행되지 않음 (idempotent)

**반환값**: 옮겨진 경우 true, 아닌 경우 false
