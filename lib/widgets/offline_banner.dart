import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/network/network_status.dart';
import 'package:hansol_high_school/network/offline_queue_manager.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = NetworkStatus.isOffline;
  SyncStatus _syncStatus = SyncStatus.idle();
  StreamSubscription<bool>? _networkSub;
  StreamSubscription<SyncStatus>? _syncSub;

  @override
  void initState() {
    super.initState();
    _networkSub = NetworkStatus.onStatusChange.listen((offline) {
      if (mounted && offline != _isOffline) {
        setState(() => _isOffline = offline);
      }
    });
    _syncSub = OfflineQueueManager.instance.onSyncStatusChange.listen((status) {
      if (mounted) setState(() => _syncStatus = status);
    });
  }

  @override
  void dispose() {
    _networkSub?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _syncStatus.state == SyncState.pending ||
        _syncStatus.state == SyncState.syncing;

    if (!_isOffline && !hasPending) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;

    if (_syncStatus.state == SyncState.syncing) {
      return _buildBanner(
        color: Colors.orange,
        icon: Icons.sync,
        text: l.offline_syncing,
        spinning: true,
      );
    }

    if (_isOffline && hasPending) {
      return _buildBanner(
        color: Colors.red,
        icon: Icons.wifi_off,
        text: '${l.offline_status} · ${l.offline_pendingCount(_syncStatus.pendingCount)}',
      );
    }

    if (_isOffline) {
      return _buildBanner(
        color: Colors.red,
        icon: Icons.wifi_off,
        text: l.offline_status,
      );
    }

    return _buildBanner(
      color: Colors.orange,
      icon: Icons.cloud_upload_outlined,
      text: l.offline_pendingCount(_syncStatus.pendingCount),
    );
  }

  Widget _buildBanner({
    required Color color,
    required IconData icon,
    required String text,
    bool spinning = false,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 6, bottom: 6),
      color: color,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (spinning)
            const SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white,
              ),
            )
          else
            Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(text,
            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
