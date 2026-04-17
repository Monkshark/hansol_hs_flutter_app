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
  static const _cacheKey = 'dday_cache';
  static const _legacyKey = 'dday_list';

  static DocumentReference<Map<String, dynamic>> _docRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('sync').doc('ddays');

  static Future<List<DDay>> loadAll() async {
    if (!AuthService.isLoggedIn) return _loadFromCache();

    await _migrateFromSecureStorage();

    try {
      final uid = AuthService.currentUser!.uid;
      final doc = await _docRef(uid).get();
      if (doc.exists && doc.data() != null) {
        final list = doc.data()!['items'] as List<dynamic>?;
        if (list != null && list.isNotEmpty) {
          final ddays = list.map((e) => DDay.fromJson(Map<String, dynamic>.from(e))).toList();
          _saveToCache(ddays);
          return ddays;
        }
      }
      return [];
    } catch (e) {
      log('DDayManager: Firestore load error: $e, falling back to cache');
      return _loadFromCache();
    }
  }

  static Future<void> saveAll(List<DDay> list) async {
    _saveToCache(list);
    if (!AuthService.isLoggedIn) return;
    try {
      final uid = AuthService.currentUser!.uid;
      await _docRef(uid).set({
        'items': list.map((e) => e.toJson()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      log('DDayManager: Firestore save error: $e');
    }
  }

  static Future<DDay?> getPinned() async {
    final list = await loadAll();
    final pinned = list.where((d) => d.isPinned && d.dDay >= 0).toList();
    if (pinned.isEmpty) return null;
    pinned.sort((a, b) => a.dDay.compareTo(b.dDay));
    return pinned.first;
  }


  static Future<List<DDay>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null || json.isEmpty) return [];
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => DDay.fromJson(e)).toList();
    } catch (e) {
      log('DDayManager: cache load error: $e');
      return [];
    }
  }

  static Future<void> _saveToCache(List<DDay> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(list.map((e) => e.toJson()).toList()));
    } catch (e) {
      log('DDayManager: cache save error: $e');
    }
  }


  static Future<void> _migrateFromSecureStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('dday_migrated') == true) return;

      final legacyPlain = prefs.getString(_legacyKey);
      List<DDay>? ddays;

      if (legacyPlain != null && legacyPlain.isNotEmpty) {
        final list = jsonDecode(legacyPlain) as List<dynamic>;
        ddays = list.map((e) => DDay.fromJson(e)).toList();
        await prefs.remove(_legacyKey);
      }

      if (ddays == null) {
        final secureJson = await SecureStorageService.read(SecureStorageService.keyDdays);
        if (secureJson != null && secureJson.isNotEmpty) {
          final list = jsonDecode(secureJson) as List<dynamic>;
          ddays = list.map((e) => DDay.fromJson(e)).toList();
        }
      }

      if (ddays != null && ddays.isNotEmpty) {
        final uid = AuthService.currentUser!.uid;
        final existingDoc = await _docRef(uid).get();
        if (!existingDoc.exists || existingDoc.data()?['items'] == null) {
          await _docRef(uid).set({
            'items': ddays.map((e) => e.toJson()).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          log('DDayManager: migrated ${ddays.length} D-days to Firestore');
        }
      }

      await SecureStorageService.delete(SecureStorageService.keyDdays);
      await prefs.setBool('dday_migrated', true);
    } catch (e) {
      log('DDayManager: migration error: $e');
    }
  }
}
