import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// 오프라인 상태 배너
///
/// - 네트워크 연결 끊기면 상단에 빨간 배너 표시
/// - 재연결 시 자동으로 사라짐
class OfflineBanner extends StatefulWidget {
  const OfflineBanner({Key? key}) : super(key: key);

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.isEmpty || results.contains(ConnectivityResult.none);
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.red,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text('오프라인 상태입니다',
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
