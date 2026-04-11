import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DDay {
  final String title;
  final DateTime date;
  final bool isPinned;

  DDay({required this.title, required this.date, this.isPinned = false});

  Map<String, dynamic> toJson() => {
    'title': title,
    'date': date.toIso8601String(),
    'isPinned': isPinned,
  };

  factory DDay.fromJson(Map<String, dynamic> json) => DDay(
    title: json['title'],
    date: DateTime.parse(json['date']),
    isPinned: json['isPinned'] ?? false,
  );

  int get dDay {
    final now = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(now).inDays;
  }
}

class DDayManager {
  static const _key = 'dday_list';

  static Future<List<DDay>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    await SecureStorageService.migrateFromPlain(
      key: SecureStorageService.keyDdays,
      oldValue: prefs.getString(_key),
      onMigrated: () async => prefs.remove(_key),
    );
    final json = await SecureStorageService.read(SecureStorageService.keyDdays);
    if (json == null || json.isEmpty) {
      if (AuthService.isLoggedIn) {
        return _loadFromFirestore();
      }
      return [];
    }
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => DDay.fromJson(e)).toList();
  }

  static Future<void> saveAll(List<DDay> list) async {
    await SecureStorageService.write(
      SecureStorageService.keyDdays,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
    _syncToFirestore(list);
  }

  static Future<DDay?> getPinned() async {
    final list = await loadAll();
    final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
    if (pinned.isEmpty) return null;
    pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
    return pinned.first;
  }

  static Future<List<DDay>> _loadFromFirestore() async {
    try {
      final uid = AuthService.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('sync').doc('ddays')
          .get();
      if (doc.exists && doc.data() != null) {
        final list = doc.data()!['items'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final ddays = list.map((e) => DDay.fromJson(Map<String, dynamic>.from(e))).toList();
          await SecureStorageService.write(
            SecureStorageService.keyDdays,
            jsonEncode(ddays.map((e) => e.toJson()).toList()),
          );
          log('DDayManager: loaded ${ddays.length} D-days from Firestore');
          return ddays;
        }
      }
    } catch (e) {
      log('DDayManager: Firestore load error: $e');
    }
    return [];
  }

  static Future<void> _syncToFirestore(List<DDay> list) async {
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('sync').doc('ddays')
          .set({
        'items': list.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('DDayManager: Firestore sync error: $e');
    }
  }
}
