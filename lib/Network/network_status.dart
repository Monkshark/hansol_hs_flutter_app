import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkStatus {
  static Future<bool> isConnected() async {
    ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();

    return connectivityResult != ConnectivityResult.none;
  }

  static Future<bool> isUnconnected() async {
    ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();

    return connectivityResult == ConnectivityResult.none;
  }

  static Future<String> getConnectionType() async {
    ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();

    switch (connectivityResult) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      default:
        return 'None';
    }
  }
}
