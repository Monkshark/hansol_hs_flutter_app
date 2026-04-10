import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/screens/board/admin/admin_widgets.dart';
import 'package:hansol_high_school/screens/board/admin/delete_logs_tab.dart';
import 'package:hansol_high_school/screens/board/admin/popup_notice_manager.dart';
import 'package:hansol_high_school/screens/board/admin/reports_tab.dart';
import 'package:hansol_high_school/screens/board/admin/users_tab.dart';
import 'package:hansol_high_school/screens/sub/feedback_list_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 관리자 화면 (AdminScreen)
///
/// - 신고된 게시글/댓글 목록 확인 및 처리
/// - 가입 대기 사용자 승인/거절/삭제
/// - 승인된 사용자 관리 및 매니저 권한 임명
class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _pendingKey = GlobalKey<UsersTabState>();
  final _suspendedKey = GlobalKey<UsersTabState>();
  final _approvedKey = GlobalKey<UsersTabState>();

  void _refreshAllTabs() {
    _pendingKey.currentState?.refresh();
    _suspendedKey.currentState?.refresh();
    _approvedKey.currentState?.refresh();
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
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
        children: [
          AdminSection(title: AppLocalizations.of(context)!.admin_userManagement, icon: Icons.people_outline, color: AppColors.theme.primaryColor, cardColor: cardColor, children: [
            AdminTile(title: AppLocalizations.of(context)!.admin_usersPending, icon: Icons.hourglass_top, color: Colors.orange, cardColor: cardColor, child: UsersTab(key: _pendingKey, filter: 'pending', onChanged: _refreshAllTabs)),
            const SizedBox(height: 8),
            AdminTile(title: AppLocalizations.of(context)!.admin_usersSuspended, icon: Icons.block, color: Colors.red,
              cardColor: cardColor, child: UsersTab(key: _suspendedKey, filter: 'suspended', onChanged: _refreshAllTabs)),
            const SizedBox(height: 8),
            AdminTile(title: AppLocalizations.of(context)!.admin_usersApproved, icon: Icons.person_outline, color: AppColors.theme.primaryColor,
              cardColor: cardColor, child: UsersTab(key: _approvedKey, filter: 'approved', onChanged: _refreshAllTabs)),
          ]),
          const SizedBox(height: 16),

          AdminSection(title: AppLocalizations.of(context)!.admin_boardManagement, icon: Icons.article_outlined, color: AppColors.theme.tertiaryColor, cardColor: cardColor, children: [
            AdminTile(title: AppLocalizations.of(context)!.admin_reportsTab, icon: Icons.flag_outlined, color: Colors.red, cardColor: cardColor, child: ReportsTab()),
            const SizedBox(height: 8),
            AdminTile(title: AppLocalizations.of(context)!.admin_deleteLogs, icon: Icons.delete_outline, color: AppColors.theme.darkGreyColor,
              cardColor: cardColor, child: const DeleteLogsTab()),
          ]),
          const SizedBox(height: 16),

          AdminSection(title: AppLocalizations.of(context)!.admin_feedback, icon: Icons.mail_outline, color: const Color(0xFF4CAF50), cardColor: cardColor, children: [
            AdminTile(title: AppLocalizations.of(context)!.admin_feedbackCouncil, icon: Icons.school_outlined, color: const Color(0xFF4CAF50), cardColor: cardColor, child: const FeedbackListScreen(type: 'council')),
            const SizedBox(height: 8),
            AdminTile(title: AppLocalizations.of(context)!.admin_feedbackApp, icon: Icons.bug_report_outlined, color: AppColors.theme.primaryColor,
              cardColor: cardColor, child: const FeedbackListScreen(type: 'app')),
          ]),
          const SizedBox(height: 16),

          AdminSection(title: AppLocalizations.of(context)!.admin_emergencyNotice, icon: Icons.warning_amber_rounded, color: Colors.red, cardColor: cardColor, children: [
            PopupNoticeManager(cardColor: cardColor),
          ]),
        ],
      ),
    ),
    );
  }
}
