import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/dday_manager.dart';
import 'package:hansol_high_school/screens/sub/dday_screen.dart';
import 'package:hansol_high_school/data/meal.dart';
import 'package:hansol_high_school/data/setting_data.dart';
import 'package:hansol_high_school/screens/board/admin_screen.dart';
import 'package:hansol_high_school/screens/board/board_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_list_screen.dart';
import 'package:hansol_high_school/screens/board/notification_screen.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/screens/sub/setting_screen.dart';
import 'package:hansol_high_school/screens/sub/timetable_view_screen.dart';
import 'package:hansol_high_school/widgets/home/current_subject_card.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// 홈 화면 (HomeScreen)
///
/// - 고정 헤더에 현재 날짜, D-day, 학년/반 정보를 표시
/// - 오늘의 급식 미리보기 카드 제공
/// - 시간표 및 게시판 바로가기 카드 배치
/// - 최신 게시글 목록을 Firestore에서 실시간 조회
/// - 외부 링크(학교 홈페이지 등) 바로가기 지원
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Key _ddayKey = UniqueKey();

  void _refreshDDay() {
    setState(() => _ddayKey = UniqueKey());
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('M월 d일 EEEE', 'ko_KR').format(now);
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
                padding: const EdgeInsets.fromLTRB(24, 8, 12, 16),
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
                              fontSize: 14,
                            ),
                          ),
                        ),
                        FutureBuilder<UserProfile?>(
                          future: AuthService.getCachedProfile(),
                          builder: (context, snap) {
                            if (snap.data?.isManager == true) {
                              return IconButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                                ),
                                icon: const Icon(Icons.shield_outlined),
                                color: Colors.white,
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
                              final unread = snap.data?.docs.length ?? 0;
                              return Stack(
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => const NotificationScreen()),
                                    ),
                                    icon: const Icon(Icons.notifications_outlined),
                                    color: Colors.white,
                                  ),
                                  if (unread > 0)
                                    Positioned(
                                      right: 8, top: 8,
                                      child: Container(
                                        width: 16, height: 16,
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
                        ),
                      ],
                    ),
                    _UpcomingEventDDay(key: _ddayKey, onRefresh: _refreshDDay),
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
                          const Icon(Icons.school, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            SettingData().isGradeSet
                                ? '한솔고 $grade학년 $classNum반'
                                : '한솔고등학교',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _TodayLunchPreview(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                  const CurrentSubjectCard(),
                  const SizedBox(height: 16),
                  GestureDetector(
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
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.theme.tertiaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calendar_view_week, color: AppColors.theme.tertiaryColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('시간표', style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                                Text('이번 주 시간표를 확인하세요', style: TextStyle(
                                  fontSize: 12, color: AppColors.theme.darkGreyColor)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BoardScreen()),
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
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.theme.primaryColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.forum_outlined, color: AppColors.theme.primaryColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('게시판', style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                                Text('자유롭게 소통해보세요', style: TextStyle(
                                  fontSize: 12, color: AppColors.theme.darkGreyColor)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (AuthService.isLoggedIn)
                    GestureDetector(
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
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.theme.secondaryColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.chat_outlined, color: AppColors.theme.secondaryColor, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('채팅', style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                                  Text('1:1 대화하기', style: TextStyle(
                                    fontSize: 12, color: AppColors.theme.darkGreyColor)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.theme.darkGreyColor),
                          ],
                        ),
                      ),
                    ),
                  if (AuthService.isLoggedIn) const SizedBox(height: 8),
                  _RecentPosts(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _LinkCard(icon: Icons.school_outlined, label: 'NEIS+', color: const Color(0xFF4CAF50), url: 'https://neisplus.kr/')),
                      const SizedBox(width: 12),
                      Expanded(child: _LinkCard(icon: Icons.language_outlined, label: '리로스쿨', color: const Color(0xFF2196F3), url: 'https://sjhansol.riroschool.kr/')),
                      const SizedBox(width: 12),
                      Expanded(child: _LinkCard(icon: Icons.campaign_outlined, label: '한솔 공식', color: const Color(0xFFFF9800), url: 'https://sjhansol.sjeduhs.kr/sjhansol-h/main.do?sso=ok')),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventDDay extends StatelessWidget {
  final VoidCallback onRefresh;
  const _UpcomingEventDDay({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DDay?>(
      future: DDayManager.getPinned(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Text(
            '일정 로딩중...',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
          );
        }

        final pinnedDDay = snapshot.data;

        if (pinnedDDay == null) {
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DDayScreen()),
            ).then((_) => onRefresh()),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.white.withAlpha(200), size: 20),
                const SizedBox(width: 8),
                Text(
                  'D-day를 설정하세요',
                  style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        final d = pinnedDDay.dDay;
        final dDayText = d == 0 ? 'D-Day' : d > 0 ? 'D-$d' : 'D+${-d}';
        final titleText = '${pinnedDDay.title} · ${DateFormat('M/d', 'ko_KR').format(pinnedDDay.date)}';

        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DDayScreen()),
          ).then((_) => onRefresh()),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                dDayText,
                style: const TextStyle(
                  color: Colors.white, fontSize: 28,
                  fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  titleText,
                  style: TextStyle(
                    color: Colors.white.withAlpha(220),
                    fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TodayLunchPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Meal?>(
      future: MealDataApi.getMeal(
        date: DateTime.now(),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      ),
      builder: (context, snapshot) {
        String preview = '급식 정보 로딩중...';
        if (snapshot.hasData && snapshot.data?.meal != null) {
          final menu = snapshot.data!.meal!;
          final items = menu.split('\n').take(3).map((e) =>
            e.replaceAll(RegExp(r'\([0-9.,\s]+\)'), '').trim()
          ).where((e) => e.isNotEmpty).join(' · ');
          preview = '🍱 $items';
        } else if (snapshot.hasData) {
          preview = '오늘 급식 정보가 없습니다';
        }
        return Text(
          preview,
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}

class _RecentPosts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return StreamBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
      stream: _combinedStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final pinnedDocs = snapshot.data![0].docs;
        final recentDocs = snapshot.data![1].docs;

        // Take most recent pinned post (by pinnedAt)
        QueryDocumentSnapshot<Map<String, dynamic>>? pinnedPost;
        if (pinnedDocs.isNotEmpty) {
          pinnedPost = pinnedDocs.first;
        }

        // Take up to 2 non-pinned recent posts (exclude pinned ones)
        final pinnedIds = pinnedDocs.map((d) => d.id).toSet();
        final nonPinned = recentDocs.where((d) => !pinnedIds.contains(d.id)).take(2).toList();

        final displayDocs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        if (pinnedPost != null) displayDocs.add(pinnedPost);
        displayDocs.addAll(nonPinned);

        if (displayDocs.isEmpty) return const SizedBox.shrink();

        return Column(
          children: displayDocs.map((doc) {
            final data = doc.data();
            final title = data['title'] ?? '';
            final category = data['category'] ?? '';
            final commentCount = data['commentCount'] ?? 0;
            final isPinned = data['isPinned'] == true;

            return GestureDetector(
              onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => PostDetailScreen(postId: doc.id))),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E2028) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    if (isPinned)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.push_pin, size: 12, color: Colors.red),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: _catColor(category).withAlpha(20),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(category,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _catColor(category))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(title,
                        style: TextStyle(fontSize: 13, color: textColor),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (commentCount > 0) ...[
                      const SizedBox(width: 6),
                      Text('[$commentCount]',
                        style: TextStyle(fontSize: 11, color: AppColors.theme.primaryColor)),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Stream<List<QuerySnapshot<Map<String, dynamic>>>> _combinedStream() {
    final pinnedStream = FirebaseFirestore.instance
        .collection('posts')
        .where('isPinned', isEqualTo: true)
        .orderBy('pinnedAt', descending: true)
        .limit(1)
        .snapshots();

    final recentStream = FirebaseFirestore.instance
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots();

    return pinnedStream.asyncExpand((pinnedSnap) {
      return recentStream.map((recentSnap) => [pinnedSnap, recentSnap]);
    });
  }

  Color _catColor(String c) {
    switch (c) {
      case '자유': return AppColors.theme.primaryColor;
      case '질문': return AppColors.theme.secondaryColor;
      case '정보공유': return AppColors.theme.tertiaryColor;
      default: return AppColors.theme.darkGreyColor;
    }
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;
  const _LinkCard({required this.icon, required this.label, required this.color, required this.url});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
            ],
          ),
        ),
      ),
    );
  }
}
