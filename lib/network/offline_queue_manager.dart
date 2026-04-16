import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/network/network_status.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// 오프라인 쓰기 큐 매니저.
///
/// 오프라인 상태에서 발생한 Firestore 쓰기 작업을 sqflite에 저장하고,
/// 네트워크 복원 시 자동으로 순서대로 재실행한다.
class OfflineQueueManager {
  OfflineQueueManager._();
  static final instance = OfflineQueueManager._();

  Database? _db;
  StreamSubscription<bool>? _networkSub;
  bool _isSyncing = false;

  // ─── 동기화 상태 스트림 ───

  final _syncController = StreamController<SyncStatus>.broadcast();

  /// 동기화 상태 변경 스트림
  Stream<SyncStatus> get onSyncStatusChange => _syncController.stream;

  /// 현재 대기 중인 작업 수
  int _pendingCount = 0;
  int get pendingCount => _pendingCount;

  // ─── 초기화 ───

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_queue.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE queue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            payload TEXT NOT NULL,
            createdAt INTEGER NOT NULL,
            retryCount INTEGER DEFAULT 0
          )
        ''');
      },
    );

    await _refreshPendingCount();
    _startListening();
  }

  void _startListening() {
    _networkSub = NetworkStatus.onStatusChange.listen((offline) {
      if (!offline && _pendingCount > 0) {
        _processQueue();
      }
    });
  }

  Future<void> dispose() async {
    await _networkSub?.cancel();
    await _syncController.close();
    await _db?.close();
    _db = null;
  }

  // ─── 큐에 작업 추가 ───

  /// 글 작성을 큐에 저장
  Future<int> enqueuePost(Map<String, dynamic> postData) async {
    return _enqueue('create_post', postData);
  }

  /// 댓글 작성을 큐에 저장
  Future<int> enqueueComment(String postId, Map<String, dynamic> commentData) async {
    return _enqueue('create_comment', {
      'postId': postId,
      'commentData': commentData,
    });
  }

  Future<int> _enqueue(String type, Map<String, dynamic> payload) async {
    final db = _db;
    if (db == null) return -1;

    // serverTimestamp 플레이스홀더 → 나중에 replay 시 실제 값으로 교체
    final sanitized = _sanitizeForStorage(payload);

    final id = await db.insert('queue', {
      'type': type,
      'payload': jsonEncode(sanitized),
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'retryCount': 0,
    });

    await _refreshPendingCount();
    _syncController.add(SyncStatus.pending(_pendingCount));
    log('OfflineQueue: enqueued $type (id=$id, pending=$_pendingCount)');
    return id;
  }

  // ─── 큐 처리 ───

  Future<void> _processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncController.add(SyncStatus.syncing(_pendingCount));

    final db = _db;
    if (db == null) {
      _isSyncing = false;
      return;
    }

    try {
      while (true) {
        final rows = await db.query('queue', orderBy: 'createdAt ASC', limit: 1);
        if (rows.isEmpty) break;

        // 네트워크 끊기면 중단
        if (await NetworkStatus.isUnconnected()) break;

        final row = rows.first;
        final id = row['id'] as int;
        final type = row['type'] as String;
        final payload = jsonDecode(row['payload'] as String) as Map<String, dynamic>;
        final retryCount = row['retryCount'] as int;

        try {
          await _executeOperation(type, payload);
          await db.delete('queue', where: 'id = ?', whereArgs: [id]);
          log('OfflineQueue: completed $type (id=$id)');
        } catch (e) {
          log('OfflineQueue: failed $type (id=$id, retry=$retryCount): $e');
          if (retryCount >= 3) {
            // 3번 실패하면 포기
            await db.delete('queue', where: 'id = ?', whereArgs: [id]);
            log('OfflineQueue: dropped $type after 3 retries (id=$id)');
          } else {
            await db.update('queue',
              {'retryCount': retryCount + 1},
              where: 'id = ?', whereArgs: [id],
            );
            break; // 실패하면 다음 연결 복원 시 재시도
          }
        }

        await _refreshPendingCount();
        _syncController.add(SyncStatus.syncing(_pendingCount));
      }
    } finally {
      _isSyncing = false;
      await _refreshPendingCount();
      _syncController.add(
        _pendingCount > 0
            ? SyncStatus.pending(_pendingCount)
            : SyncStatus.idle(),
      );
    }
  }

  Future<void> _executeOperation(String type, Map<String, dynamic> payload) async {
    final db = FirebaseFirestore.instance;

    switch (type) {
      case 'create_post':
        final data = _restoreTimestamps(payload);
        await db.collection('posts').add(data);
        break;
      case 'create_comment':
        final postId = payload['postId'] as String;
        final commentData = _restoreTimestamps(
          Map<String, dynamic>.from(payload['commentData'] as Map),
        );
        await db.collection('posts').doc(postId).collection('comments').add(commentData);
        await db.collection('posts').doc(postId).update({
          'commentCount': FieldValue.increment(1),
        });
        break;
    }
  }

  // ─── 유틸리티 ───

  Future<void> _refreshPendingCount() async {
    final db = _db;
    if (db == null) {
      _pendingCount = 0;
      return;
    }
    final result = await db.rawQuery('SELECT COUNT(*) as cnt FROM queue');
    _pendingCount = Sqflite.firstIntValue(result) ?? 0;
  }

  /// 수동 동기화 트리거 (UI에서 호출)
  Future<void> syncNow() async {
    if (await NetworkStatus.isUnconnected()) return;
    await _processQueue();
  }

  /// 큐 비우기 (사용자가 취소)
  Future<void> clearQueue() async {
    await _db?.delete('queue');
    await _refreshPendingCount();
    _syncController.add(SyncStatus.idle());
  }

  /// FieldValue.serverTimestamp()는 JSON 직렬화 불가 → 플레이스홀더로 교체
  Map<String, dynamic> _sanitizeForStorage(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value is FieldValue) {
        result[entry.key] = '__SERVER_TIMESTAMP__';
      } else if (entry.value is Map) {
        result[entry.key] = _sanitizeForStorage(Map<String, dynamic>.from(entry.value as Map));
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// 플레이스홀더를 실제 FieldValue.serverTimestamp()로 복원
  Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      if (entry.value == '__SERVER_TIMESTAMP__') {
        result[entry.key] = FieldValue.serverTimestamp();
      } else if (entry.value is Map) {
        result[entry.key] = _restoreTimestamps(Map<String, dynamic>.from(entry.value as Map));
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }
}

/// 동기화 상태
class SyncStatus {
  final SyncState state;
  final int pendingCount;

  const SyncStatus._(this.state, this.pendingCount);

  factory SyncStatus.idle() => const SyncStatus._(SyncState.idle, 0);
  factory SyncStatus.pending(int count) => SyncStatus._(SyncState.pending, count);
  factory SyncStatus.syncing(int count) => SyncStatus._(SyncState.syncing, count);
}

enum SyncState { idle, pending, syncing }
