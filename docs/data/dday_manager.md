# DDayManager

> `lib/data/dday_manager.dart` — D-day CRUD, Firestore 동기화

`DDay` 모델과 `DDayManager` 클래스를 포함. 모든 메서드가 `static`. 데이터는 [`SecureStorageService`](secure_storage_service.md)에 저장.

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

시간 부분을 제거하고 날짜 차이만 계산. 양수면 미래, 0이면 당일, 음수면 과거.

---

## `loadAll`

```dart
static Future<List<DDay>> loadAll()
```

**설명**: 전체 D-day 목록을 로드한다.

1. SharedPreferences → SecureStorage 일회성 마이그레이션:
   ```dart
   await SecureStorageService.migrateFromPlain(
     key: SecureStorageService.keyDdays,
     oldValue: prefs.getString(_key),
     onMigrated: () async => prefs.remove(_key),
   );
   ```

2. SecureStorage에서 JSON 읽기:
   ```dart
   final json = await SecureStorageService.read(SecureStorageService.keyDdays);
   ```

3. 로컬 데이터가 없고 로그인 상태면 Firestore에서 복원:
   ```dart
   if (json == null || json.isEmpty) {
     if (AuthService.isLoggedIn) {
       return _loadFromFirestore();
     }
     return [];
   }
   ```

---

## `saveAll`

```dart
static Future<void> saveAll(List<DDay> list)
```

**설명**: D-day 목록 전체를 저장하고 Firestore에 동기화한다.

```dart
await SecureStorageService.write(
  SecureStorageService.keyDdays,
  jsonEncode(list.map((e) => e.toJson()).toList()),
);
_syncToFirestore(list);  // fire-and-forget
```

Firestore 동기화는 비동기로 실행 (실패해도 로컬은 저장됨).

---

## `getPinned`

```dart
static Future<DDay?> getPinned()
```

**설명**: 핀 된 D-day 중 가장 가까운 미래 항목을 반환한다.

```dart
final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
return pinned.first;
```

홈 화면 상단 D-day 위젯에 표시되는 항목.

---

## `_loadFromFirestore`

```dart
static Future<List<DDay>> _loadFromFirestore()
```

**설명**: Firestore `users/{uid}/sync/ddays` 문서에서 D-day 목록을 복원한다.

```dart
final doc = await FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('sync').doc('ddays')
    .get();
```

복원 후 SecureStorage에도 저장하여 다음 로드 시 로컬에서 읽히도록 함.

---

## `_syncToFirestore`

```dart
static Future<void> _syncToFirestore(List<DDay> list)
```

**설명**: D-day 목록을 Firestore에 동기화한다.

```dart
await FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('sync').doc('ddays')
    .set({
  'items': list.map((e) => e.toJson()).toList(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

비로그인 상태면 즉시 return. 에러는 로깅만 (silent fail).
