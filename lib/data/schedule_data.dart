/// 개인일정 데이터 모델
///
/// - 시작/종료 시간, 내용, 날짜, 종료 날짜(연속일정), 색상 포함
/// - Map 변환 (toMap/fromMap)으로 DB 저장/조회 지원
class Schedule {
  final int? id;
  final int startTime;
  final int endTime;
  final String content;
  final String date;
  final String? endDate; // 연속일정 종료 날짜 (null이면 하루일정)
  final int color; // 0xFFRRGGBB

  Schedule({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.content,
    required this.date,
    this.endDate,
    this.color = 0xFF3F72AF,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'startTime': startTime,
    'endTime': endTime,
    'content': content,
    'date': date,
    'endDate': endDate,
    'color': color,
  };

  factory Schedule.fromMap(Map<String, dynamic> map) => Schedule(
    id: map['id'] as int?,
    startTime: map['startTime'] as int,
    endTime: map['endTime'] as int,
    content: map['content'] as String,
    date: map['date'] as String,
    endDate: map['endDate'] as String?,
    color: map['color'] as int? ?? 0xFF3F72AF,
  );
}
