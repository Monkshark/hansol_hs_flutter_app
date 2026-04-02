import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/schedule_data.dart';

void main() {
  group('Schedule', () {
    test('toMap and fromMap roundtrip', () {
      final schedule = Schedule(
        id: 1,
        startTime: 540,
        endTime: 600,
        content: '수학 공부',
        date: '2026-04-01T00:00:00.000',
      );

      final map = schedule.toMap();
      final restored = Schedule.fromMap(map);

      expect(restored.id, 1);
      expect(restored.startTime, 540);
      expect(restored.endTime, 600);
      expect(restored.content, '수학 공부');
    });

    test('toMap without id excludes id', () {
      final schedule = Schedule(
        startTime: 480,
        endTime: 540,
        content: '조회',
        date: '2026-04-01',
      );

      final map = schedule.toMap();
      expect(map.containsKey('id'), false);
    });

    test('toMap with id includes id', () {
      final schedule = Schedule(
        id: 5,
        startTime: 480,
        endTime: 540,
        content: '조회',
        date: '2026-04-01',
      );

      final map = schedule.toMap();
      expect(map['id'], 5);
    });
  });
}
