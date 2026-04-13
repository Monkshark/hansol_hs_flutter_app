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
}
