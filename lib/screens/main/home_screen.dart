import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/providers/home_provider.dart';
import 'package:hansol_high_school/screens/board/admin_screen.dart';
import 'package:hansol_high_school/screens/board/board_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_list_screen.dart';
import 'package:hansol_high_school/screens/board/notification_screen.dart';
import 'package:hansol_high_school/screens/sub/setting_screen.dart';
import 'package:hansol_high_school/screens/sub/timetable_view_screen.dart';
import 'package:hansol_high_school/screens/sub/grade_screen.dart';
import 'package:hansol_high_school/widgets/home/current_subject_card.dart';
import 'package:hansol_high_school/widgets/home/home_header_widgets.dart';
import 'package:hansol_high_school/widgets/home/link_card.dart';
import 'package:hansol_high_school/widgets/home/recent_posts.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  void refresh() {
    if (!mounted) return;
    ref.invalidate(pinnedDDayProvider);
    ref.invalidate(todayLunchProvider);
    setState(() {});
  }

  void _refreshDDay() {
    ref.invalidate(pinnedDDayProvider);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l = AppLocalizations.of(context)!;
    final dateStr = DateFormat(l.common_dateMdEEEE, Localizations.localeOf(context).toString()).format(now);
    final grade = SettingData().grade;
    final classNum = SettingData().classNum;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.theme.primaryColor,
                  AppColors.theme.tertiaryColor,
                ],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Responsive.w(context, 24), Responsive.h(context, 8), Responsive.w(context, 12), Responsive.h(context, 16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              color: Colors.white.withAlpha(200),
                              fontSize: Responsive.sp(context, 14),
                            ),
                          ),
                        ),
                        FutureBuilder<UserProfile?>(
                          future: AuthService.getCachedProfile(),
                          builder: (context, snap) {
                            if (snap.hasError) return const SizedBox.shrink();
                            if (snap.data?.isManager == true) {
                              return IconButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                                ),
                                icon: const Icon(Icons.shield_outlined),
                                color: Colors.white,
                                tooltip: l.home_admin,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        if (AuthService.isLoggedIn)
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(AuthService.currentUser!.uid)
                                .collection('notifications')
                                .where('read', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snap) {
                              if (snap.hasError) return const SizedBox.shrink();
                              final unread = snap.data?.docs.length ?? 0;
                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                    ),
                                    icon: const Icon(Icons.notifications_outlined),
                                    color: Colors.white,
                                    tooltip: l.home_notification,
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      right: Responsive.r(context, 8), top: Responsive.r(context, 8),
                                      child: Container(
                                        width: Responsive.r(context, 16), height: Responsive.r(context, 16),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(child: Text(
                                          unread > 9 ? '9+' : '$unread',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                                        )),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingScreen()),
                          ),
                          icon: const Icon(Icons.settings_outlined),
                          color: Colors.white,
                          tooltip: l.home_settings,
                        ),
                      ],
                    ),
                    UpcomingEventDDay(onRefresh: _refreshDDay),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school, color: Colors.white, size: Responsive.r(context, 16)),
                          const SizedBox(width: 6),
                          Text(
                            SettingData().isGradeSet
                                ? AppLocalizations.of(context)!.home_schoolInfo(grade, classNum)
                                : AppLocalizations.of(context)!.home_schoolName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: Responsive.sp(context, 13),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const TodayLunchPreview(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => refresh(),
              color: AppColors.theme.primaryColor,
              child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  if (AuthService.cachedProfile?.isGraduate != true) ...[
                    const CurrentSubjectCard(),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: l.home_timetableTitle,
                      child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TimetableViewScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2028) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: Responsive.r(context, 40), height: Responsive.r(context, 40),
                              decoration: BoxDecoration(
                                color: AppColors.theme.tertiaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.calendar_view_week, color: AppColors.theme.tertiaryColor, size: Responsive.r(context, 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.home_timetableTitle, style: TextStyle(
                                    fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w600, color: textColor)),
                                  Text(AppLocalizations.of(context)!.home_timetableSubtitle, style: TextStyle(
                                    fontSize: Responsive.sp(context, 12), color: AppColors.theme.darkGreyColor)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                          ],
                        ),
                      ),
                    )),
                    const SizedBox(height: 8),
                  ],
                  Semantics(
                    button: true,
                    label: l.home_gradesTitle,
                    child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GradeScreen()),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E2028) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: Responsive.r(context, 40), height: Responsive.r(context, 40),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.trending_up, color: const Color(0xFFE53935), size: Responsive.r(context, 22)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.home_gradesTitle, style: TextStyle(
                                  fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w600, color: textColor)),
                                Text(AppLocalizations.of(context)!.home_gradesSubtitle, style: TextStyle(
                                  fontSize: Responsive.sp(context, 12), color: AppColors.theme.darkGreyColor)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                        ],
                      ),
                    ),
                  )),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2028) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Semantics(
                          button: true,
                          label: l.home_boardTitle,
                          child: GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const BoardScreen())),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: Responsive.r(context, 40), height: Responsive.r(context, 40),
                                  decoration: BoxDecoration(
                                    color: AppColors.theme.primaryColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.forum_outlined, color: AppColors.theme.primaryColor, size: Responsive.r(context, 22)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(AppLocalizations.of(context)!.home_boardTitle, style: TextStyle(
                                        fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w600, color: textColor)),
                                      Text(AppLocalizations.of(context)!.home_boardSubtitle, style: TextStyle(
                                        fontSize: Responsive.sp(context, 12), color: AppColors.theme.darkGreyColor)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                              ],
                            ),
                          ),
                        )),
                        Divider(height: 1, color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFEEEEEE)),
                        const RecentPosts(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (AuthService.isLoggedIn)
                    Semantics(
                      button: true,
                      label: l.home_chatTitle,
                      child: GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ChatListScreen())),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E2028) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: Responsive.r(context, 40), height: Responsive.r(context, 40),
                              decoration: BoxDecoration(
                                color: AppColors.theme.secondaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.chat_outlined, color: AppColors.theme.secondaryColor, size: Responsive.r(context, 22)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(AppLocalizations.of(context)!.home_chatTitle, style: TextStyle(
                                    fontSize: Responsive.sp(context, 15), fontWeight: FontWeight.w600, color: textColor)),
                                  Text(AppLocalizations.of(context)!.home_chatSubtitle, style: TextStyle(
                                    fontSize: Responsive.sp(context, 12), color: AppColors.theme.darkGreyColor)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                          ],
                        ),
                      ),
                    )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: LinkCard(icon: Icons.school_outlined, label: 'NEIS+', color: Color(0xFF4CAF50), url: 'https://neisplus.kr/')),
                      const SizedBox(width: 12),
                      Expanded(child: LinkCard(icon: Icons.language_outlined, label: AppLocalizations.of(context)!.home_linkRiroschool, color: const Color(0xFF2196F3), url: 'https://sjhansol.riroschool.kr/')),
                      const SizedBox(width: 12),
                      Expanded(child: LinkCard(icon: Icons.campaign_outlined, label: AppLocalizations.of(context)!.home_linkOfficial, color: const Color(0xFFFF9800), url: 'https://sjhansol.sjeduhs.kr/sjhansol-h/main.do?sso=ok')),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

