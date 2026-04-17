# DDayManager

> `lib/data/dday_manager.dart` — D-day CRUD, Firestore 동기화

`DDay` 모델과 `DDayManager` 클래스를 포함. 모든 메서드가 `static`. 주 저장소는 Firestore (`users/{uid}/sync/ddays`), 오프라인 캐시는 SharedPreferences (`dday_cache` 키). D-day 데이터는 날짜와 라벨뿐이므로 암호화 불필요

---

## DDay (데이터 모델)

```dart
class DDay {
  final String title;
  final DateTime date;
  final bool isPinned;
}
```

### `dDay` (계산 프로퍼티)

```dart
int get dDay {
  final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(now).inDays;
}
```

시간 부분을 제거하고 날짜 차이만 계산. 양수면 미래, 0이면 당일, 음수면 과거

---

## `loadAll`

```dart
static Future<List<DDay>> loadAll()
```

**설명**: 전체 D-day 목록을 로드함

1. 비로그인 상태면 SharedPreferences 캐시에서 로드:
   ```dart
   if (!AuthService.isLoggedIn) return _loadFromCache();
   ```

2. 일회성 마이그레이션 실행 ([SecureStorage → Firestore](#_migratefromsecurestorage))

3. Firestore에서 읽기:
   ```dart
   final doc = await _docRef(uid).get();
   ```

4. 성공 시 캐시에도 저장하여 오프라인 대비

5. Firestore 에러 시 캐시 폴백:
   ```dart
   catch (e) {
     log('DDayManager: Firestore load error: $e, falling back to cache');
     return _loadFromCache();
   }
   ```

---

## `saveAll`

```dart
static Future<void> saveAll(List<DDay> list)
```

**설명**: D-day 목록 전체를 저장함

1. 항상 SharedPreferences 캐시에 먼저 저장 (오프라인 보장)
2. 로그인 상태면 Firestore에 동기화:
   ```dart
   await _docRef(uid).set({
     'items': list.map((e) => e.toJson()).toList(),
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

Firestore 에러는 로깅만 (캐시는 이미 저장됨)

---

## `getPinned`

```dart
static Future<DDay?> getPinned()
```

**설명**: 핀 된 D-day 중 가장 가까운 미래 항목을 반환함

```dart
final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
return pinned.first;
```

홈 화면 상단 D-day 위젯에 표시되는 항목

---

## `_loadFromCache` / `_saveToCache`

SharedPreferences `dday_cache` 키를 사용하는 오프라인 캐시. 평문 저장 (D-day 데이터는 민감하지 않으므로 암호화 불필요)

- `_loadFromCache`: 캐시에서 D-day 목록 로드
- `_saveToCache`: D-day 목록을 캐시에 저장

---

## `_migrateFromSecureStorage`

```dart
static Future<void> _migrateFromSecureStorage()
```

**설명**: [`SecureStorageService`](secure_storage_service.md)에서 Firestore로 일회성 마이그레이션

- SharedPreferences `dday_migrated` 플래그로 중복 실행 방지
- 레거시 SharedPreferences 키(`dday_list`) + SecureStorage 확인
- Firestore 문서가 없을 때만 업로드
- 마이그레이션 후 SecureStorage 데이터 삭제
