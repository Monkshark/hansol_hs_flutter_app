# SecureStorageService

> 한국어: [secure_storage_service.md](./secure_storage_service.md)

> `lib/data/secure_storage_service.dart` — Encrypted storage wrapper

`flutter_secure_storage` wrapper. All methods are `static`. On error, **silent fail** (logs only; returns no data).

---

## Storage policy

| Stored here | Not stored here |
|-------------|----------------|
| Academic records (grades, goals) | Cache (timetable/meal/notice) — fast reads, plaintext OK |
| Personally-identifying info like D-day | Firebase Auth / Kakao SDK tokens — managed by the SDKs themselves |

---

## Key constants

```dart
static const String keyGradeExams = 'secure_grade_exams';
static const String keyGradeGoals = 'secure_grade_goals';
static const String keyGradeJeongsiGoals = 'secure_grade_jeongsi_goals';
static const String keyDdays = 'secure_ddays';
```

The namespace prefix (`secure_`) prevents collisions with SharedPreferences keys.

---

## Platform configuration

```dart
static const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

- **Android**: Uses `EncryptedSharedPreferences` (AES-256, backed by the Android Keystore)
- **iOS**: Keychain, `first_unlock` — accessible after the first unlock following boot. Readable even from background tasks

---

## Error-handling strategy

Every method wraps a `try/catch` + `log()`. **Silent-fail principle**:

| Method | On error | Rationale |
|--------|----------|-----------|
| `read` | returns `null` | Callers treat null as "no data" → show an empty list |
| `write` | ignored (log only) | Next write will retry; data loss is preferable to app crash |
| `delete` | ignored (log only) | Failed deletion only leaves data behind; not dangerous |
| `deleteAll` | ignored (log only) | Called on account deletion — Auth deletion already prevents re-access |

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

### Known platform errors

- **After Android reinstall**: The Keystore key remains but the EncryptedSharedPreferences file is wiped → `PlatformException`. Self-heals because read returns null
- **iOS Keychain access denied**: Attempting a background read before the device is unlocked fails. Minimized by `first_unlock`, but possible in edge-case timing

---

## `read` / `write` / `delete` / `deleteAll`

```dart
static Future<String?> read(String key)
static Future<void> write(String key, String value)
static Future<void> delete(String key)
static Future<void> deleteAll()
```

Basic CRUD. All values are serialized as String (JSON). Callers ([`GradeManager`](grade_manager.md), [`DDayManager`](dday_manager.md)) handle `jsonEncode`/`jsonDecode`.

---

## `migrateFromPlain`

```dart
static Future<bool> migrateFromPlain({
  required String key,
  required String? oldValue,
  required Future<void> Function() onMigrated,
})
```

**Description**: One-shot migration helper from SharedPreferences (plaintext) → SecureStorage (encrypted).

```dart
if (oldValue == null || oldValue.isEmpty) return false;  // nothing to migrate
final existing = await read(key);
if (existing != null && existing.isNotEmpty) return false;  // already exists
await write(key, oldValue);      // encrypted write
await onMigrated();              // caller removes the plaintext from SharedPreferences
```

- Runs automatically on the first call to [`GradeManager`](grade_manager.md)`.loadExams`, [`DDayManager`](dday_manager.md)`.loadAll`, etc.
- **Idempotent**: Returns `false` when already migrated; safe to re-run
- The `onMigrated` callback deletes the plaintext key → prevents residual plaintext data after migration

**Returns**: `true` when migrated, `false` otherwise.

**Regression coverage**: 8 unit tests — validating cases like successful migration, failure, already-exists, and empty values.
