import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';

class ErrorView extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;
  final String? errorType;

  const ErrorView({
    super.key,
    this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.errorType,
  });

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.logErrorShown(errorType: widget.errorType ?? 'generic');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              widget.message ?? l10n.error_generic,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (widget.onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l10n.error_retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
