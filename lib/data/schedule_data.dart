class Schedule {
  final int? id;
  final int startTime;
  final int endTime;
  final String content;
  final String date;

  Schedule({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.content,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'startTime': startTime,
    'endTime': endTime,
    'content': content,
    'date': date,
  };

  factory Schedule.fromMap(Map<String, dynamic> map) => Schedule(
    id: map['id'] as int?,
    startTime: map['startTime'] as int,
    endTime: map['endTime'] as int,
    content: map['content'] as String,
    date: map['date'] as String,
  );
}
