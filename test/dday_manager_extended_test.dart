import 'package:flutter_test/flutter_test.dart';
import 'package:hansol_high_school/data/dday_manager.dart';

void main() {
  group('DDay sorting and filtering', () {
    test('sort by dDay ascending', () {
      final today = DateTime.now();
      final list = [
        DDay(title: 'far', date: today.add(const Duration(days: 30))),
        DDay(title: 'near', date: today.add(const Duration(days: 3))),
        DDay(title: 'mid', date: today.add(const Duration(days: 10))),
      ];
      list.sort((a, b) => a.dDay.compareTo(b.dDay));
      expect(list[0].title, 'near');
      expect(list[1].title, 'mid');
      expect(list[2].title, 'far');
    });

    test('filter pinned and future only', () {
      final today = DateTime.now();
      final list = [
        DDay(title: 'pinned future', date: today.add(const Duration(days: 5)), isPinned: true),
        DDay(title: 'pinned past', date: today.subtract(const Duration(days: 5)), isPinned: true),
        DDay(title: 'unpinned future', date: today.add(const Duration(days: 3)), isPinned: false),
        DDay(title: 'pinned today', date: DateTime(today.year, today.month, today.day), isPinned: true),
      ];
      final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
      pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
      expect(pinned.length, 2);
      expect(pinned[0].title, 'pinned today');
      expect(pinned[1].title, 'pinned future');
    });

    test('no pinned items returns empty', () {
      final today = DateTime.now();
      final list = [
        DDay(title: 'a', date: today.add(const Duration(days: 5)), isPinned: false),
      ];
      final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
      expect(pinned, isEmpty);
    });
  });

  group('DDay serialization list', () {
    test('serialize and deserialize list', () {
      final list = [
        DDay(title: '중간고사', date: DateTime(2026, 5, 10), isPinned: true),
        DDay(title: '기말고사', date: DateTime(2026, 7, 15), isPinned: false),
      ];
      final jsonList = list.map((e) => e.toJson()).toList();
      final restored = jsonList.map((e) => DDay.fromJson(e)).toList();

      expect(restored.length, 2);
      expect(restored[0].title, '중간고사');
      expect(restored[0].isPinned, true);
      expect(restored[1].title, '기말고사');
      expect(restored[1].isPinned, false);
    });

    test('empty list roundtrip', () {
      final list = <DDay>[];
      final jsonList = list.map((e) => e.toJson()).toList();
      final restored = jsonList.map((e) => DDay.fromJson(e)).toList();
      expect(restored, isEmpty);
    });
  });

  group('DDay edge cases', () {
    test('far future date (100 days)', () {
      final dday = DDay(title: 'far', date: DateTime.now().add(const Duration(days: 100)));
      expect(dday.dDay, 100);
    });

    test('far past date', () {
      final dday = DDay(title: 'old', date: DateTime.now().subtract(const Duration(days: 365)));
      expect(dday.dDay, -365);
    });

    test('same day at different times still 0', () {
      final now = DateTime.now();
      final earlyMorning = DateTime(now.year, now.month, now.day, 1, 0);
      final lateNight = DateTime(now.year, now.month, now.day, 23, 59);
      expect(DDay(title: 'a', date: earlyMorning).dDay, 0);
      expect(DDay(title: 'b', date: lateNight).dDay, 0);
    });
  });
}
