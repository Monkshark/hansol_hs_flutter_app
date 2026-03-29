import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: const Text('Admin'),
        centerTitle: true,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.theme.primaryColor,
          unselectedLabelColor: AppColors.theme.darkGreyColor,
          indicatorColor: AppColors.theme.primaryColor,
          tabs: const [
            Tab(text: '신고'),
            Tab(text: '승인 대기'),
            Tab(text: '승인됨'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ReportsTab(),
          _UsersTab(showApproved: false),
          _UsersTab(showApproved: true),
        ],
      ),
    );
  }
}

// 신고 탭
class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Text('신고가 없습니다',
            style: TextStyle(color: AppColors.theme.darkGreyColor)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final reason = data['reason'] ?? '';
            final postId = data['postId'] ?? '';
            final time = (data['createdAt'] as Timestamp?)?.toDate();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2028) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(reason, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.red)),
                      ),
                      const Spacer(),
                      if (time != null)
                        Text('${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: AppColors.theme.darkGreyColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId))),
                          child: Text('글 보기', style: TextStyle(
                            fontSize: 13, color: AppColors.theme.primaryColor, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          // 글 + 댓글 삭제
                          try {
                            final comments = await FirebaseFirestore.instance
                                .collection('posts').doc(postId).collection('comments').get();
                            for (var c in comments.docs) await c.reference.delete();
                            await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                          } catch (_) {}
                          await docs[index].reference.delete();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('글 삭제', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => docs[index].reference.delete(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.theme.darkGreyColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('무시', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// 사용자 탭 (승인 대기 / 승인됨)
class _UsersTab extends StatelessWidget {
  final bool showApproved;
  const _UsersTab({required this.showApproved});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final approved = d.data()['approved'] == true;
          return showApproved ? approved : !approved;
        }).toList();

        if (docs.isEmpty) {
          return Center(child: Text(
            showApproved ? '승인된 사용자가 없습니다' : '대기 중인 사용자가 없습니다',
            style: TextStyle(color: AppColors.theme.darkGreyColor)));
        }

        return FutureBuilder<UserProfile?>(
          future: AuthService.getCachedProfile(),
          builder: (context, myProfileSnap) {
            final myProfile = myProfileSnap.data;
            final isAdmin = myProfile?.isAdmin ?? false;

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final data = docs[index].data();
                final uid = docs[index].id;
                final name = data['name'] ?? '-';
                final studentId = data['studentId'] ?? '-';
                final grade = data['grade'] ?? 0;
                final classNum = data['classNum'] ?? 0;
                final role = data['role'] ?? 'user';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2028) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: role == 'manager'
                            ? AppColors.theme.secondaryColor
                            : AppColors.theme.primaryColor,
                        child: Text(name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                                if (role == 'manager') ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.theme.secondaryColor.withAlpha(20),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text('매니저', style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.theme.secondaryColor)),
                                  ),
                                ],
                              ],
                            ),
                            Text('$studentId · ${grade}학년 ${classNum}반',
                              style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                          ],
                        ),
                      ),
                      if (!showApproved) ...[
                        // 승인 대기 → 승인/거절
                        _actionBtn('승인', AppColors.theme.primaryColor, () async {
                          await docs[index].reference.update({'approved': true});
                        }),
                        const SizedBox(width: 6),
                        _actionBtn('거절', Colors.red, () async {
                          await docs[index].reference.delete();
                        }),
                      ] else ...[
                        // 승인됨 → 매니저 임명 (admin만)
                        // 자기 자신이 admin이면 셀프 해제
                        if (isAdmin && role == 'admin' && uid == AuthService.currentUser?.uid)
                          _actionBtn('Admin 해제', AppColors.theme.darkGreyColor, () async {
                            await docs[index].reference.update({'role': 'user'});
                            AuthService.clearProfileCache();
                          }),
                        if (isAdmin && role != 'admin') ...[
                          _actionBtn(
                            role == 'manager' ? '매니저 해제' : '매니저',
                            role == 'manager' ? AppColors.theme.darkGreyColor : AppColors.theme.secondaryColor,
                            () async {
                              await docs[index].reference.update({
                                'role': role == 'manager' ? 'user' : 'manager',
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          _actionBtn(
                            'Admin',
                            Colors.red,
                            () async {
                              await docs[index].reference.update({'role': 'admin'});
                            },
                          ),
                        ],
                      ],
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _actionBtn(String text, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
