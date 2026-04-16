# LocalDataBase

> 한국어: [local_database.md](./local_database.md)

> `lib/data/local_database.dart` — SQLite schedule DB, Firestore sync

Instance methods (registered as a singleton with GetIt). sqflite-based personal schedule CRUD.

---

## Database schema

```sql
CREATE TABLE schedules (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  startTime INTEGER NOT NULL,
  endTime INTEGER NOT NULL,
  content TEXT NOT NULL,
  date TEXT NOT NULL,
  endDate TEXT,
  color INTEGER DEFAULT 4284811951
)
```

- `date`: `'2026-04-10'` format
- `endDate`: for multi-day schedules (added in v2)
- `color`: ARGB integer value (default = grey)

---

## `database` (getter)

```dart
Future<Database> get database async {
  if (_db != null) return _db!;
  _db = await _initDB();
  return _db!;
}
```

Lazy singleton pattern. Creates/opens the DB on first call.

---

## `_initDB`

```dart
Future<Database> _initDB()
```

**Description**: Opens the SQLite DB and creates the schema.

```dart
return openDatabase(
  path,
  version: 2,
  onCreate: (db, version) async { /* CREATE TABLE */ },
  onUpgrade: (db, oldVersion, newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE schedules ADD COLUMN endDate TEXT');
      await db.execute('ALTER TABLE schedules ADD COLUMN color INTEGER DEFAULT 4284811951');
    }
  },
);
```

v1→v2 migration: adds `endDate`, `color` columns.

---

## `migrateFromPrefs`

```dart
Future<void> migrateFromPrefs()
```

**Description**: Migrates legacy schedule data from SharedPreferences to SQLite.

```dart
final old = prefs.getStringList('schedules');
final batch = db.batch();
for (var json in old) {
  batch.insert('schedules', {...});
}
await batch.commit(noResult: true);
await prefs.remove('schedules');
```

Optimizes performance with batch inserts. Deletes the original after migration.

---

## `insertSchedule`

```dart
Future<int> insertSchedule(Schedule schedule)
```

After inserting a schedule, calls `syncToFirestore()`. Returns the auto-increment ID.

---

## `deleteSchedule`

```dart
Future<void> deleteSchedule(Schedule schedule)
```

**Description**: Deletes a schedule. Matches by ID if present; otherwise matches by composite conditions.

```dart
if (schedule.id != null) {
  await db.delete('schedules', where: 'id = ?', whereArgs: [schedule.id]);
} else {
  await db.delete('schedules',
    where: 'startTime = ? AND endTime = ? AND content = ? AND date = ?',
    whereArgs: [...],
  );
}
```

Calls `syncToFirestore()` after deletion.

---

## `watchSchedules`

```dart
Stream<List<Schedule>> watchSchedules(DateTime date)
```

**Description**: Returns the schedule list for a specific date as a stream.

```dart
final results = await db.query(
  'schedules',
  where: "date LIKE ? OR (endDate IS NOT NULL AND date <= ? AND endDate >= ?)",
  whereArgs: ['$dateStr%', '$dateStr', '$dateStr'],
  orderBy: 'startTime ASC',
);
```

Includes multi-day schedules too: condition `date <= query date <= endDate`.

> **Note**: Currently yields once with `async*` and then terminates. This is a one-time query, not a real-time update.

---

## `getSchedulesForDateRange`

```dart
Future<List<Schedule>> getSchedulesForDateRange(DateTime start, int days)
```

Queries schedules for `days` days starting from `start`. Runs individual queries per date.

---

## `syncToFirestore`

```dart
Future<void> syncToFirestore()
```

**Description**: Syncs the entire schedule list to Firestore.

```dart
final all = await _getAllSchedules();
await FirebaseFirestore.instance
    .collection('users').doc(uid)
    .collection('sync').doc('schedules')
    .set({
  'items': all.map((s) => s.toMap()).toList(),
  'updatedAt': FieldValue.serverTimestamp(),
});
```

Called automatically after every CRUD operation. Skipped when not logged in.

---

## `loadFromFirestore`

```dart
Future<void> loadFromFirestore()
```

**Description**: Restores schedules from Firestore (only when the local DB is empty).

```dart
final existing = await db.query('schedules');
if (existing.isNotEmpty) return;  // skip if local data exists
```

Used for restoration on device change/reinstall. Optimized with batch inserts.
