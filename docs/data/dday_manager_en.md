# DDayManager

> 한국어: [dday_manager.md](./dday_manager.md)

> `lib/data/dday_manager.dart` — D-day CRUD, Firestore sync

Contains the `DDay` model and the `DDayManager` class. All methods are `static`. Data is stored in [`SecureStorageService`](secure_storage_service.md).

---

## DDay (data model)

```dart
class DDay {
  final String title;
  final DateTime date;
  final bool isPinned;
}
```

### `dDay` (computed property)

```dart
int get dDay {
  final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final target = DateTime(date.year, date.month, date.day);
  return target.difference(now).inDays;
}
```

Strips the time component and calculates only the date difference. Positive is future, 0 is today, negative is past.

---

## `loadAll`

```dart
static Future<List<DDay>> loadAll()
```

**Description**: Loads the full list of D-days.

1. One-time migration from SharedPreferences to SecureStorage:
   ```dart
   await SecureStorageService.migrateFromPlain(
     key: SecureStorageService.keyDdays,
     oldValue: prefs.getString(_key),
     onMigrated: () async => prefs.remove(_key),
   );
   ```

2. Read JSON from SecureStorage:
   ```dart
   final json = await SecureStorageService.read(SecureStorageService.keyDdays);
   ```

3. Restore from Firestore if no local data exists and the user is logged in:
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

**Description**: Saves the entire D-day list and syncs to Firestore.

```dart
await SecureStorageService.write(
  SecureStorageService.keyDdays,
  jsonEncode(list.map((e) => e.toJson()).toList()),
);
_syncToFirestore(list);  // fire-and-forget
```

Firestore sync runs asynchronously (local is saved even if sync fails).

---

## `getPinned`

```dart
static Future<DDay?> getPinned()
```

**Description**: Returns the closest upcoming item among pinned D-days.

```dart
final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
return pinned.first;
```

Item displayed in the D-day widget at the top of the home screen.

---

## `_loadFromFirestore`

```dart
static Future<List<DDay>> _loadFromFirestore()
```

**Description**: Restores the D-day list from the Firestore `users/{uid}/sync/ddays` document.

```dart
final doc = await FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('sync').doc('ddays')
    .get();
```

After restoring, also stores to SecureStorage so the next load reads from local.

---

## `_syncToFirestore`

```dart
static Future<void> _syncToFirestore(List<DDay> list)
```

**Description**: Syncs the D-day list to Firestore.

```dart
await FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('sync').doc('ddays')
    .set({
  'items': list.map((e) => e.toJson()).toList(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

Returns immediately if not logged in. Errors are only logged (silent fail).
