import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            startTime INTEGER NOT NULL,
            endTime INTEGER NOT NULL,
            content TEXT NOT NULL,
            date TEXT NOT NULL,
            endDate TEXT,
            color INTEGER DEFAULT 4284811951
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE schedules ADD COLUMN endDate TEXT');
          await db.execute('ALTER TABLE schedules ADD COLUMN color INTEGER DEFAULT 4284811951');
        }
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
    final id = await db.insert('schedules', schedule.toMap());
    syncToFirestore();
    return id;
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
    syncToFirestore();
  }

  Stream<List<Schedule>> watchSchedules(DateTime date) async* {
    final db = await database;

    final dateStr = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final results = await db.query(
      'schedules',
      where: "date LIKE ? OR (endDate IS NOT NULL AND date <= ? AND endDate >= ?)",
      whereArgs: ['$dateStr%', '$dateStr', '$dateStr'],
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

  Future<List<Schedule>> _getAllSchedules() async {
    final db = await database;
    final rows = await db.query('schedules', orderBy: 'date ASC, startTime ASC');
    return rows.map((row) => Schedule.fromMap(row)).toList();
  }

  Future<void> syncToFirestore() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final all = await _getAllSchedules();
      final uid = AuthService.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('sync').doc('schedules')
          .set({
        'items': all.map((s) => s.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('LocalDataBase: Firestore sync error: $e');
    }
  }

  Future<void> loadFromFirestore() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final db = await database;
      final existing = await db.query('schedules');
      if (existing.isNotEmpty) return;

      final uid = AuthService.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('sync').doc('schedules')
          .get();

      if (doc.exists && doc.data() != null) {
        final list = doc.data()!['items'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final batch = db.batch();
          for (var item in list) {
            final map = Map<String, dynamic>.from(item);
            map.remove('id');
            batch.insert('schedules', map);
          }
          await batch.commit(noResult: true);
          log('LocalDataBase: loaded ${list.length} schedules from Firestore');
        }
      }
    } catch (e) {
      log('LocalDataBase: Firestore load error: $e');
    }
  }
}
