# Schedule

> `lib/data/schedule_data.dart` — 개인일정 데이터 모델

SQLite `schedules` 테이블과 1:1 매핑되는 순수 Dart 클래스. freezed를 사용하지 않고 수동 `toMap`/`fromMap` 제공

---

## 필드

```dart
class Schedule {
  final int? id;          // SQLite auto-increment PK. 새 일정은 null
  final int startTime;    // 시작 시간 (0~23, 시 단위)
  final int endTime;      // 종료 시간 (0~23, 시 단위)
  final String content;   // 일정 내용
  final String date;      // 시작 날짜 ('2026-04-10' 형식)
  final String? endDate;  // 종료 날짜 (연속일정용. null이면 하루일정)
  final int color;        // 0xFFRRGGBB 형태. 기본값 0xFF3F72AF (파란색)
}
```

- `startTime`/`endTime`: 시(hour) 단위 정수. 예: 9시~12시 → `startTime: 9, endTime: 12`
- `endDate`: v2 스키마에서 추가. 여러 날에 걸치는 일정 지원
- `color`: 사용자가 캘린더에서 선택한 색상. 기본값은 앱 primaryColor

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

SQLite 삽입용. `id`가 null이면 맵에서 제외 → auto-increment로 자동 생성

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

SQLite 쿼리 결과에서 Schedule 객체 생성. `color`가 null(v1 데이터)이면 기본 파란색

---

## 사용처

| 위치 | 용도 |
|------|------|
| `LocalDataBase.insertSchedule` | Schedule → toMap → SQLite insert |
| `LocalDataBase.watchSchedules` | SQLite row → fromMap → Schedule 리스트 |
| `LocalDataBase.syncToFirestore` | Schedule → toMap → Firestore 동기화 |
| `ScheduleBottomSheet` | 사용자 입력으로 Schedule 객체 생성 |
| `ScheduleCard` | Schedule 필드를 캘린더 카드에 표시 |
