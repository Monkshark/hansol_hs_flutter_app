import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/responsive.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;
  const LinkCard({required this.icon, required this.label, required this.color, required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Container(
                  width: Responsive.r(context, 44), height: Responsive.r(context, 44),
                  decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: Responsive.r(context, 24)),
                ),
                SizedBox(height: Responsive.h(context, 8)),
                Text(label, style: TextStyle(fontSize: Responsive.sp(context, 13), fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
