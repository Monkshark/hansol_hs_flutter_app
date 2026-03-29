import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatus {
  static Future<bool> isUnconnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }
}
