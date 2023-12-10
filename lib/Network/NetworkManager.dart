import 'package:connectivity/connectivity.dart';

class NetworkManager {
  static Future<bool> isConnected() async {
    ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();

    return connectivityResult != ConnectivityResult.none;
  }
}
