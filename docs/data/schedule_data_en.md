# Schedule

> 한국어: [schedule_data.md](./schedule_data.md)

> `lib/data/schedule_data.dart` — Personal schedule data model

A plain Dart class mapped 1:1 to the SQLite `schedules` table. Does not use freezed; provides hand-written `toMap`/`fromMap`.

---

## Fields

```dart
class Schedule {
  final int? id;          // SQLite auto-increment PK. null for new schedules
  final int startTime;    // Start hour (0–23)
  final int endTime;      // End hour (0–23)
  final String content;   // Schedule content
  final String date;      // Start date (format '2026-04-10')
  final String? endDate;  // End date (for multi-day schedules; null means single day)
  final int color;        // 0xFFRRGGBB format. Default 0xFF3F72AF (blue)
}
```

- `startTime`/`endTime`: Integer hour values. Example: 9:00–12:00 → `startTime: 9, endTime: 12`
- `endDate`: Added in schema v2. Supports schedules spanning multiple days
- `color`: Color chosen by the user in the calendar. Defaults to the app's primaryColor

---

## `toMap`

```dart
Map<String, dynamic> toMap() => {
  if (id != null) 'id': id,
  'startTime': startTime,
  'endTime': endTime,
  'content': content,
  'date': date,
  'endDate': endDate,
  'color': color,
};
```

Used for SQLite inserts. When `id` is null, it is excluded from the map so auto-increment can generate it.

---

## `fromMap`

```dart
factory Schedule.fromMap(Map<String, dynamic> map) => Schedule(
  id: map['id'] as int?,
  startTime: map['startTime'] as int,
  endTime: map['endTime'] as int,
  content: map['content'] as String,
  date: map['date'] as String,
  endDate: map['endDate'] as String?,
  color: map['color'] as int? ?? 0xFF3F72AF,
);
```

Creates a Schedule object from a SQLite query result. When `color` is null (v1 data), defaults to blue.

---

## Usage

| Location | Purpose |
|----------|---------|
| `LocalDataBase.insertSchedule` | Schedule → toMap → SQLite insert |
| `LocalDataBase.watchSchedules` | SQLite row → fromMap → Schedule list |
| `LocalDataBase.syncToFirestore` | Schedule → toMap → Firestore sync |
| `ScheduleBottomSheet` | Creates Schedule objects from user input |
| `ScheduleCard` | Displays Schedule fields on calendar cards |
