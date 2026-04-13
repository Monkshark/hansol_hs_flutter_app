# SecureStorageService

> `lib/data/secure_storage_service.dart` — 암호화 저장소 래퍼

`flutter_secure_storage` wrapper. 모든 메서드가 `static`. 에러 시 **silent fail** (데이터 반환 없이 로깅만)

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

네임스페이스 prefix(`secure_`)로 SharedPreferences 키와 충돌 방지

---

## 플랫폼 설정

```dart
static const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

- **Android**: `EncryptedSharedPreferences` 사용 (AES-256, Android Keystore 기반)
- **iOS**: Keychain, `first_unlock` — 기기 부팅 후 최초 잠금 해제 이후 접근 가능. 백그라운드 작업에서도 읽기 가능

---

## 에러 처리 전략

모든 메서드에 `try/catch` + `log()` 적용. **Silent fail 원칙**:

| 메서드 | 에러 시 동작 | 근거 |
|--------|-------------|------|
| `read` | `null` 반환 | 호출부가 null을 "데이터 없음"으로 처리 → 빈 목록 표시 |
| `write` | 무시 (로깅만) | 다음 write 시 재시도됨, 앱 크래시보다 데이터 유실이 나음 |
| `delete` | 무시 (로깅만) | 삭제 실패 시 데이터가 남아있을 뿐 위험하지 않음 |
| `deleteAll` | 무시 (로깅만) | 회원 탈퇴 시 호출 — 실패해도 Auth 삭제로 재접근 불가 |

```dart
static Future<String?> read(String key) async {
  try {
    return await _storage.read(key: key);
  } catch (e) {
    log('SecureStorage read failed for $key: $e', name: 'SecureStorage');
    return null;
  }
}
```

### 알려진 플랫폼 에러

- **Android 앱 재설치 후**: Keystore 키가 남아있지만 EncryptedSharedPreferences 파일이 삭제됨 → `PlatformException` 발생. read에서 null 반환으로 자연 복구
- **iOS Keychain 접근 거부**: 기기 잠금 해제 전 백그라운드에서 읽기 시도 시 실패. `first_unlock` 설정으로 최소화했지만 극단적 타이밍에서 발생 가능

---

## `read` / `write` / `delete` / `deleteAll`

```dart
static Future<String?> read(String key)
static Future<void> write(String key, String value)
static Future<void> delete(String key)
static Future<void> deleteAll()
```

기본 CRUD. 모든 값은 String으로 직렬화 (JSON)하여 저장. 호출부([`GradeManager`](grade_manager.md), [`DDayManager`](dday_manager.md))가 `jsonEncode`/`jsonDecode` 담당

---

## `migrateFromPlain`

```dart
static Future<bool> migrateFromPlain({
  required String key,
  required String? oldValue,
  required Future<void> Function() onMigrated,
})
```

**설명**: SharedPreferences(평문) → SecureStorage(암호화) 일회성 마이그레이션 helper

```dart
if (oldValue == null || oldValue.isEmpty) return false;  // 옮길 게 없음
final existing = await read(key);
if (existing != null && existing.isNotEmpty) return false;  // 이미 있음
await write(key, oldValue);      // 암호화 저장
await onMigrated();              // 호출부가 SharedPreferences에서 삭제
```

- [`GradeManager`](grade_manager.md)`.loadExams`, [`DDayManager`](dday_manager.md)`.loadAll` 등에서 첫 호출 시 자동 실행
- **Idempotent**: 이미 마이그레이션된 경우 `false` 반환, 재실행 안전
- `onMigrated` 콜백에서 평문 키 삭제 → 마이그레이션 완료 후 평문 데이터 잔존 방지

**반환값**: 옮겨진 경우 `true`, 아닌 경우 `false`

**회귀 방지**: unit test 8개 — 마이그레이션 성공/실패/이미 존재/빈 값 등 케이스 검증
