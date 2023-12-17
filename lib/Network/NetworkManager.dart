import 'package:connectivity/connectivity.dart';

class NetworkConnectivity {
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
}
