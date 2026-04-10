# LocalDataBase

> `lib/data/local_database.dart` — SQLite 일정 DB, Firestore 동기화

인스턴스 메서드 (GetIt에 싱글턴 등록). sqflite 기반 개인 일정 CRUD.

---

## 데이터베이스 스키마

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

- `date`: `'2026-04-10'` 형식
- `endDate`: 여러 날에 걸치는 일정용 (v2에서 추가)
- `color`: ARGB 정수값 (기본값 = 회색)

---

## `database` (getter)

```dart
Future<Database> get database async {
  if (_db != null) return _db!;
  _db = await _initDB();
  return _db!;
}
```

Lazy singleton 패턴. 최초 호출 시 DB 생성/열기.

---

## `_initDB`

```dart
Future<Database> _initDB()
```

**설명**: SQLite DB를 열고 스키마를 생성한다.

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

v1→v2 마이그레이션: `endDate`, `color` 컬럼 추가.

---

## `migrateFromPrefs`

```dart
Future<void> migrateFromPrefs()
```

**설명**: SharedPreferences의 레거시 일정 데이터를 SQLite로 마이그레이션한다.

```dart
final old = prefs.getStringList('schedules');
final batch = db.batch();
for (var json in old) {
  batch.insert('schedules', {...});
}
await batch.commit(noResult: true);
await prefs.remove('schedules');
```

배치 삽입으로 성능 최적화. 마이그레이션 후 원본 삭제.

---

## `insertSchedule`

```dart
Future<int> insertSchedule(Schedule schedule)
```

일정 삽입 후 `syncToFirestore()` 호출. 반환값은 auto-increment ID.

---

## `deleteSchedule`

```dart
Future<void> deleteSchedule(Schedule schedule)
```

**설명**: 일정을 삭제한다. ID가 있으면 ID로, 없으면 복합 조건으로 매칭한다.

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

삭제 후 `syncToFirestore()` 호출.

---

## `watchSchedules`

```dart
Stream<List<Schedule>> watchSchedules(DateTime date)
```

**설명**: 특정 날짜의 일정 목록을 스트림으로 반환한다.

```dart
final results = await db.query(
  'schedules',
  where: "date LIKE ? OR (endDate IS NOT NULL AND date <= ? AND endDate >= ?)",
  whereArgs: ['$dateStr%', '$dateStr', '$dateStr'],
  orderBy: 'startTime ASC',
);
```

여러 날 일정도 포함: `date <= 조회일 <= endDate` 조건.

> **참고**: 현재 `async*`로 한 번만 yield 후 종료. 실시간 갱신이 아닌 일회성 쿼리.

---

## `getSchedulesForDateRange`

```dart
Future<List<Schedule>> getSchedulesForDateRange(DateTime start, int days)
```

`start`부터 `days`일간의 일정을 조회. 날짜별로 개별 쿼리 실행.

---

## `syncToFirestore`

```dart
Future<void> syncToFirestore()
```

**설명**: 전체 일정 목록을 Firestore에 동기화한다.

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

매 CRUD 작업 후 자동 호출. 비로그인 시 skip.

---

## `loadFromFirestore`

```dart
Future<void> loadFromFirestore()
```

**설명**: Firestore에서 일정을 복원한다 (로컬 DB가 비어있을 때만).

```dart
final existing = await db.query('schedules');
if (existing.isNotEmpty) return;  // 로컬 데이터가 있으면 skip
```

기기 변경/재설치 시 복원 용도. 배치 삽입으로 성능 최적화.
