import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatus {
  static Future<bool> isConnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.mobile);
  }

  static Future<bool> isUnconnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }

  static Future<String> getConnectionType() async {
    final results = await Connectivity().checkConnectivity();

    if (results.contains(ConnectivityResult.wifi)) {
      return 'Wi-Fi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobile';
    } else {
      return 'None';
    }
  }
}
