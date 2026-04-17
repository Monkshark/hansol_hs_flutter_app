# DDayManager

> 한국어: [dday_manager.md](./dday_manager.md)

> `lib/data/dday_manager.dart` — D-day CRUD, Firestore sync

Contains the `DDay` model and the `DDayManager` class. All methods are `static`. Primary storage is Firestore (`users/{uid}/sync/ddays`), with SharedPreferences as offline cache (`dday_cache` key). D-day data is just dates and labels, so encryption is unnecessary.

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

1. If not logged in, load from SharedPreferences cache:
   ```dart
   if (!AuthService.isLoggedIn) return _loadFromCache();
   ```

2. Run one-time migration ([SecureStorage to Firestore](#_migratefromsecurestorage))

3. Read from Firestore:
   ```dart
   final doc = await _docRef(uid).get();
   ```

4. On success, also save to cache for offline availability

5. On Firestore error, fall back to cache:
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

**Description**: Saves the entire D-day list.

1. Always save to SharedPreferences cache first (guarantees offline access)
2. If logged in, sync to Firestore:
   ```dart
   await _docRef(uid).set({
     'items': list.map((e) => e.toJson()).toList(),
     'updatedAt': FieldValue.serverTimestamp(),
   });
   ```

Firestore errors are only logged (cache is already saved).

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

## `_loadFromCache` / `_saveToCache`

Offline cache using the SharedPreferences `dday_cache` key. Stored as plaintext (D-day data is not sensitive, so encryption is unnecessary).

- `_loadFromCache`: Load D-day list from cache
- `_saveToCache`: Save D-day list to cache

---

## `_migrateFromSecureStorage`

```dart
static Future<void> _migrateFromSecureStorage()
```

**Description**: One-time migration from [`SecureStorageService`](secure_storage_service.md) to Firestore.

- Guarded by SharedPreferences `dday_migrated` flag to prevent repeated runs
- Checks legacy SharedPreferences key (`dday_list`) + SecureStorage
- Uploads to Firestore only if the document does not already exist
- Cleans up SecureStorage data after migration
