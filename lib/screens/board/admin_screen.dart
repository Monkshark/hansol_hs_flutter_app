import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/admin/admin_widgets.dart';
import 'package:hansol_high_school/screens/board/admin/delete_logs_tab.dart';
import 'package:hansol_high_school/screens/board/admin/popup_notice_manager.dart';
import 'package:hansol_high_school/screens/board/admin/reports_tab.dart';
import 'package:hansol_high_school/screens/board/admin/users_tab.dart';
import 'package:hansol_high_school/screens/sub/feedback_list_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _pendingKey = GlobalKey<UsersTabState>();
  final _suspendedKey = GlobalKey<UsersTabState>();
  final _approvedKey = GlobalKey<UsersTabState>();

  void _refreshAllTabs() {
    for (final key in [_pendingKey, _suspendedKey, _approvedKey]) {
      try {
        key.currentState?.refresh();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E2028) : Colors.white;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! > 300) Navigator.of(context).pop();
      },
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF14151A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF14151A) : const Color(0xFFF5F5F5),
        foregroundColor: textColor,
        title: const Text('Admin'),
        centerTitle: true,
        elevation: 0,
      ),
      body: FutureBuilder<UserProfile?>(
        future: AuthService.getCachedProfile(),
        builder: (context, snap) {
          final profile = snap.data;
          if (profile == null) return const Center(child: CircularProgressIndicator());
          final l = AppLocalizations.of(context)!;

          final sections = <Widget>[];

          if (profile.isManager) {
            sections.add(AdminSection(title: l.admin_userManagement, icon: Icons.people_outline, color: AppColors.theme.primaryColor, cardColor: cardColor, children: [
              AdminTile(title: l.admin_usersPending, icon: Icons.hourglass_top, color: Colors.orange, cardColor: cardColor, child: UsersTab(key: _pendingKey, filter: 'pending', onChanged: _refreshAllTabs)),
              const SizedBox(height: 8),
              AdminTile(title: l.admin_usersSuspended, icon: Icons.block, color: Colors.red,
                cardColor: cardColor, child: UsersTab(key: _suspendedKey, filter: 'suspended', onChanged: _refreshAllTabs)),
              const SizedBox(height: 8),
              AdminTile(title: l.admin_usersApproved, icon: Icons.person_outline, color: AppColors.theme.primaryColor,
                cardColor: cardColor, child: UsersTab(key: _approvedKey, filter: 'approved', onChanged: _refreshAllTabs)),
            ]));
            sections.add(const SizedBox(height: 16));
          }

          if (profile.isModerator) {
            sections.add(AdminSection(title: l.admin_boardManagement, icon: Icons.article_outlined, color: AppColors.theme.tertiaryColor, cardColor: cardColor, children: [
              AdminTile(title: l.admin_reportsTab, icon: Icons.flag_outlined, color: Colors.red, cardColor: cardColor, child: const ReportsTab()),
              const SizedBox(height: 8),
              AdminTile(title: l.admin_deleteLogs, icon: Icons.delete_outline, color: AppColors.theme.darkGreyColor,
                cardColor: cardColor, child: const DeleteLogsTab()),
            ]));
            sections.add(const SizedBox(height: 16));
          }

          if (profile.isManager || profile.isAuditor) {
            sections.add(AdminSection(title: l.admin_feedback, icon: Icons.mail_outline, color: const Color(0xFF4CAF50), cardColor: cardColor, children: [
              AdminTile(title: l.admin_feedbackCouncil, icon: Icons.school_outlined, color: const Color(0xFF4CAF50), cardColor: cardColor, child: const FeedbackListScreen(type: 'council')),
              const SizedBox(height: 8),
              AdminTile(title: l.admin_feedbackApp, icon: Icons.bug_report_outlined, color: AppColors.theme.primaryColor,
                cardColor: cardColor, child: const FeedbackListScreen(type: 'app')),
            ]));
            sections.add(const SizedBox(height: 16));
          }

          if (profile.isManager) {
            sections.add(AdminSection(title: l.admin_emergencyNotice, icon: Icons.warning_amber_rounded, color: Colors.red, cardColor: cardColor, children: [
              PopupNoticeManager(cardColor: cardColor),
            ]));
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            children: sections,
          );
        },
      ),
    ),
    );
  }
}
