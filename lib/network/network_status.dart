import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

class NetworkStatus {
  static Future<bool> Function()? _testOverride;

  @visibleForTesting
  static set testOverride(Future<bool> Function()? fn) => _testOverride = fn;

  static Future<bool> isUnconnected() async {
    if (_testOverride != null) return _testOverride!();
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }

  // ─── 스트림 기반 실시간 모니터링 ───

  static final _connectivity = Connectivity();
  static StreamController<bool>? _controller;
  static StreamSubscription<List<ConnectivityResult>>? _sub;
  static bool _lastKnown = false;

  /// 현재 연결 상태 (마지막으로 알려진 값)
  static bool get isOffline => _lastKnown;

  /// 연결 상태 변경 스트림. true = 오프라인, false = 온라인.
  /// 최초 호출 시 자동으로 리스닝 시작.
  static Stream<bool> get onStatusChange {
    _ensureListening();
    return _controller!.stream;
  }

  static void _ensureListening() {
    if (_controller != null) return;
    _controller = StreamController<bool>.broadcast(onCancel: _stopListening);
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final offline = results.isEmpty || results.contains(ConnectivityResult.none);
      if (offline != _lastKnown) {
        _lastKnown = offline;
        _controller?.add(offline);
      }
    });
    // 초기값 설정
    _connectivity.checkConnectivity().then((results) {
      _lastKnown = results.isEmpty || results.contains(ConnectivityResult.none);
      _controller?.add(_lastKnown);
    });
  }

  static void _stopListening() {
    _sub?.cancel();
    _sub = null;
    _controller?.close();
    _controller = null;
  }

  /// 테스트용 리셋
  @visibleForTesting
  static void resetStream() {
    _stopListening();
    _lastKnown = false;
  }
}
