import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class CommunityRulesScreen extends StatelessWidget {
  const CommunityRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final subColor = AppColors.theme.mealTypeTextColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l.community_rules_title),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('community_rules')
              .orderBy('publishedAt', descending: true)
              .limit(1)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return Center(child: Text(l.community_rules_empty,
                style: TextStyle(color: subColor)));
            }
            final doc = snap.data!.docs.first;
            final data = doc.data();
            final content = (data['content'] as String?) ?? '';
            final version = doc.id;
            final effectiveAt = data['effectiveAt'];
            String? effectiveDate;
            if (effectiveAt is Timestamp) {
              final d = effectiveAt.toDate();
              effectiveDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            } else if (effectiveAt is String) {
              effectiveDate = effectiveAt;
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.community_rules_version(version),
                    style: TextStyle(fontSize: 12, color: subColor)),
                  if (effectiveDate != null) ...[
                    const SizedBox(height: 4),
                    Text(l.community_rules_effectiveDate(effectiveDate),
                      style: TextStyle(fontSize: 12, color: subColor)),
                  ],
                  const SizedBox(height: 16),
                  Text(content, style: TextStyle(fontSize: 14, height: 1.6, color: textColor)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
