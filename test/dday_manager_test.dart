import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/dday_manager.dart';

void main() {
  group('DDay', () {
    test('toJson and fromJson roundtrip', () {
      final dday = DDay(
        title: '중간고사',
        date: DateTime(2026, 5, 10),
        isPinned: true,
      );

      final json = dday.toJson();
      final restored = DDay.fromJson(json);

      expect(restored.title, '중간고사');
      expect(restored.date.year, 2026);
      expect(restored.date.month, 5);
      expect(restored.date.day, 10);
      expect(restored.isPinned, true);
    });

    test('dDay calculation is correct', () {
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));
      final yesterday = today.subtract(const Duration(days: 1));

      final futureDDay = DDay(title: 'future', date: tomorrow);
      expect(futureDDay.dDay, 1);

      final pastDDay = DDay(title: 'past', date: yesterday);
      expect(pastDDay.dDay, -1);

      final todayDDay = DDay(
        title: 'today',
        date: DateTime(today.year, today.month, today.day),
      );
      expect(todayDDay.dDay, 0);
    });

    test('default isPinned is false', () {
      final dday = DDay(title: 'test', date: DateTime.now());
      expect(dday.isPinned, false);
    });

    test('fromJson handles missing isPinned', () {
      final json = {
        'title': '기말고사',
        'date': DateTime(2026, 7, 15).toIso8601String(),
      };

      final dday = DDay.fromJson(json);
      expect(dday.isPinned, false);
    });
  });
}
