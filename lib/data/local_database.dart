import 'dart:async';
import 'dart:convert';

import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/**
 * sqflite 기반 일정 데이터베이스
 *
 * - 개인 일정 CRUD (생성/조회/수정/삭제)
 * - SharedPreferences에서 sqflite로 마이그레이션 지원
 */
class LocalDataBase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'hansol_schedules.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime INTEGER NOT NULL,
            endTime INTEGER NOT NULL,
            content TEXT NOT NULL,
            date TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final old = prefs.getStringList('schedules');
    if (old == null || old.isEmpty) return;

    final db = await database;
    final batch = db.batch();
    for (var json in old) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      batch.insert('schedules', {
        'startTime': map['startTime'],
        'endTime': map['endTime'],
        'content': map['content'],
        'date': map['date'],
      });
    }
    await batch.commit(noResult: true);
    await prefs.remove('schedules');
  }

  Future<int> insertSchedule(Schedule schedule) async {
    final db = await database;
    return db.insert('schedules', schedule.toMap());
  }

  Future<void> deleteSchedule(Schedule schedule) async {
    final db = await database;
    if (schedule.id != null) {
      await db.delete('schedules', where: 'id = ?', whereArgs: [schedule.id]);
    } else {
      await db.delete('schedules',
        where: 'startTime = ? AND endTime = ? AND content = ? AND date = ?',
        whereArgs: [schedule.startTime, schedule.endTime, schedule.content, schedule.date],
      );
    }
  }

  Stream<List<Schedule>> watchSchedules(DateTime date) async* {
    final db = await database;

    final datePrefix = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'schedules',
      where: 'date LIKE ?',
      whereArgs: ['$datePrefix%'],
      orderBy: 'startTime ASC',
    );

    yield results.map((row) => Schedule.fromMap(row)).toList();
  }

  Future<List<Schedule>> getSchedulesForDateRange(DateTime start, int days) async {
    final db = await database;
    final results = <Schedule>[];

    for (int i = 0; i < days; i++) {
      final date = start.add(Duration(days: i));
      final datePrefix = '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';

      final rows = await db.query(
        'schedules',
        where: 'date LIKE ?',
        whereArgs: ['$datePrefix%'],
        orderBy: 'startTime ASC',
      );
      results.addAll(rows.map((row) => Schedule.fromMap(row)));
    }

    return results;
  }
}
