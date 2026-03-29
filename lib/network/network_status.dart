import 'package:connectivity_plus/connectivity_plus.dart';

/// 네트워크 연결 상태 확인
///
/// - connectivity_plus 플러그인으로 현재 연결 상태 조회
/// - WiFi/모바일 데이터 미연결 시 true 반환
/// - API 호출 전 오프라인 체크에 사용
class NetworkStatus {
  static Future<bool> isUnconnected() async {
    final results = await Connectivity().checkConnectivity();
    return results.isEmpty || results.contains(ConnectivityResult.none);
  }
}
