import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/board/post_detail_screen.dart';
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
          _AdminSection(title: '사용자 관리', icon: Icons.people_outline, color: AppColors.theme.primaryColor, cardColor: cardColor, children: [
            _AdminTile(title: '승인 대기', icon: Icons.hourglass_top, color: Colors.orange, initiallyExpanded: true,
              cardColor: cardColor, child: _UsersTab(filter: 'pending')),
            const SizedBox(height: 8),
            _AdminTile(title: '정지된 사용자', icon: Icons.block, color: Colors.red,
              cardColor: cardColor, child: _UsersTab(filter: 'suspended')),
            const SizedBox(height: 8),
            _AdminTile(title: '일반 사용자', icon: Icons.person_outline, color: AppColors.theme.primaryColor,
              cardColor: cardColor, child: _UsersTab(filter: 'approved')),
          ]),
          const SizedBox(height: 16),

          _AdminSection(title: '게시판 관리', icon: Icons.article_outlined, color: AppColors.theme.tertiaryColor, cardColor: cardColor, children: [
            _AdminTile(title: '신고', icon: Icons.flag_outlined, color: Colors.red, initiallyExpanded: true,
              cardColor: cardColor, child: _ReportsTab()),
            const SizedBox(height: 8),
            _AdminTile(title: '삭제 로그', icon: Icons.delete_outline, color: AppColors.theme.darkGreyColor,
              cardColor: cardColor, child: const _DeleteLogsTab()),
          ]),
          const SizedBox(height: 16),

          _AdminSection(title: '건의사항', icon: Icons.mail_outline, color: const Color(0xFF4CAF50), cardColor: cardColor, children: [
            _AdminTile(title: '학생회 건의', icon: Icons.school_outlined, color: const Color(0xFF4CAF50), initiallyExpanded: true,
              cardColor: cardColor, child: const FeedbackListScreen(type: 'council')),
            const SizedBox(height: 8),
            _AdminTile(title: '앱 건의/버그', icon: Icons.bug_report_outlined, color: AppColors.theme.primaryColor,
              cardColor: cardColor, child: const FeedbackListScreen(type: 'app')),
          ]),
          const SizedBox(height: 16),

          _AdminSection(title: '긴급 공지', icon: Icons.warning_amber_rounded, color: Colors.red, cardColor: cardColor, children: [
            _PopupNoticeManager(cardColor: cardColor),
          ]),
        ],
      ),
    ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
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

class _UsersTab extends StatelessWidget {
  final String filter;
  const _UsersTab({required this.filter});

  Future<void> _logAdminAction(String action, String targetUid, String targetName) async {
    await FirebaseFirestore.instance.collection('admin_logs').add({
      'action': action,
      'targetUid': targetUid,
      'targetName': targetName,
      'adminUid': AuthService.currentUser?.uid ?? '',
      'adminName': AuthService.cachedProfile?.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  bool _isSuspended(Map<String, dynamic> data) {
    final ts = data['suspendedUntil'] as Timestamp?;
    if (ts == null) return false;
    return DateTime.now().isBefore(ts.toDate());
  }

  String _suspendRemaining(Timestamp ts) {
    final diff = ts.toDate().difference(DateTime.now());
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final parts = <String>[];
    if (d > 0) parts.add('${d}일');
    if (h > 0) parts.add('${h}시간');
    if (m > 0) parts.add('${m}분');
    return parts.isEmpty ? '1분 미만' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data();
          final approved = data['approved'] == true;
          final suspended = _isSuspended(data);

          switch (filter) {
            case 'pending': return !approved;
            case 'approved':
              if (!approved) return false;
              if (suspended) return false;
              return true;
            case 'suspended': return approved && suspended;
            default: return false;
          }
        }).toList();

        if (filter == 'approved') {
          docs.sort((a, b) {
            final roleOrder = {'admin': 0, 'manager': 1, 'user': 2};
            final ra = roleOrder[a.data()['role'] ?? 'user'] ?? 2;
            final rb = roleOrder[b.data()['role'] ?? 'user'] ?? 2;
            return ra.compareTo(rb);
          });
        }

        final emptyMsg = {
          'pending': '대기 중인 사용자가 없습니다',
          'approved': '승인된 사용자가 없습니다',
          'suspended': '정지된 사용자가 없습니다',
        };

        if (docs.isEmpty) {
          return Center(child: Text(emptyMsg[filter] ?? '',
            style: TextStyle(color: AppColors.theme.darkGreyColor)));
        }

        return FutureBuilder<UserProfile?>(
          future: AuthService.getCachedProfile(),
          builder: (context, myProfileSnap) {
            final isAdmin = myProfileSnap.data?.isAdmin ?? false;

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: role == 'admin' ? Colors.red
                                : role == 'manager' ? AppColors.theme.secondaryColor
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
                                    Flexible(child: Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                                      overflow: TextOverflow.ellipsis)),
                                    if (role == 'admin') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red)),
                                      ),
                                    ],
                                    if (role == 'manager') ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: AppColors.theme.secondaryColor.withAlpha(20), borderRadius: BorderRadius.circular(4)),
                                        child: Text('매니저', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.theme.secondaryColor)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text('$studentId · ${grade}학년 ${classNum}반',
                                  style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                                if (filter == 'suspended') ...[
                                  const SizedBox(height: 4),
                                  Text('남은 기간: ${_suspendRemaining(data['suspendedUntil'] as Timestamp)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (filter == 'pending') ...[
                            _actionBtn('승인', AppColors.theme.primaryColor, () async {
                              await docs[index].reference.update({'approved': true});
                              await _sendAccountNotification(uid, '가입 승인', '가입이 승인되었습니다.');
                              await _logAdminAction('승인', uid, name);
                            }),
                            const SizedBox(width: 6),
                            _actionBtn('거절', Colors.red, () async {
                              await _sendAccountNotification(uid, '가입 거절', '가입이 거절되었습니다.');
                              await docs[index].reference.delete();
                              await _logAdminAction('거절', uid, name);
                            }),
                          ],
                          if (filter == 'approved') ...[
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
                                  final newRole = role == 'manager' ? 'user' : 'manager';
                                  await docs[index].reference.update({'role': newRole});
                                  await _logAdminAction('역할 변경: $newRole', uid, name);
                                },
                              ),
                              const SizedBox(width: 6),
                              _actionBtn('Admin', Colors.red, () async {
                                await docs[index].reference.update({'role': 'admin'});
                                await _logAdminAction('역할 변경: admin', uid, name);
                              }),
                            ],
                            if (uid != AuthService.currentUser?.uid && role == 'user') ...[
                              const SizedBox(width: 6),
                              _actionBtn('정지', Colors.orange, () async {
                                final hours = await _showSuspendDialog(context, name);
                                if (hours != null) {
                                  final until = DateTime.now().add(Duration(hours: hours));
                                  await docs[index].reference.update({'suspendedUntil': Timestamp.fromDate(until)});
                                  await _sendAccountNotification(uid, '계정 정지', '${_formatDuration(hours)} 동안 계정이 정지되었습니다.');
                                  await _logAdminAction('정지', uid, name);
                                }
                              }),
                              const SizedBox(width: 6),
                              _actionBtn('삭제', Colors.red, () async {
                                final first = await _confirmDialog(context, '계정 삭제', '$name 계정을 삭제하시겠습니까?');
                                if (first != true) return;
                                final second = await _confirmDialog(context, '최종 확인', '$name 계정을 정말 삭제합니까?\n되돌릴 수 없습니다.');
                                if (second == true) {
                                  await _sendAccountNotification(uid, '계정 삭제', '관리자에 의해 계정이 삭제되었습니다.');
                                  await docs[index].reference.delete();
                                  await _logAdminAction('삭제', uid, name);
                                }
                              }),
                            ],
                          ],
                          if (filter == 'suspended') ...[
                            _actionBtn('정지 해제', AppColors.theme.primaryColor, () async {
                              await docs[index].reference.update({'suspendedUntil': null});
                              await _sendAccountNotification(uid, '정지 해제', '계정 정지가 해제되었습니다.');
                              await _logAdminAction('정지 해제', uid, name);
                            }),
                          ],
                        ],
                      ),
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

  String _formatDuration(int hours) {
    if (hours < 24) return '$hours시간';
    return '${hours ~/ 24}일';
  }

  Future<int?> _showSuspendDialog(BuildContext context, String name) async {
    final options = [
      {'label': '1시간', 'hours': 1},
      {'label': '6시간', 'hours': 6},
      {'label': '12시간', 'hours': 12},
      {'label': '1일', 'hours': 24},
      {'label': '3일', 'hours': 72},
      {'label': '7일', 'hours': 168},
      {'label': '30일', 'hours': 720},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$name 정지', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(ctx).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              Text('정지 기간을 선택하세요', style: TextStyle(
                fontSize: 14, color: AppColors.theme.mealTypeTextColor)),
              const SizedBox(height: 16),
              ...options.map((o) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, o['hours'] as int),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(o['label'] as String),
                  ),
                ),
              )),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendAccountNotification(String targetUid, String title, String body) async {
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(targetUid).collection('notifications').add({
        'type': 'account',
        'postId': '',
        'postTitle': title,
        'senderName': 'Admin',
        'content': body,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<bool?> _confirmDialog(BuildContext context, String title, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(ctx).textTheme.bodyLarge?.color)),
              const SizedBox(height: 12),
              Text(content, style: TextStyle(
                fontSize: 14, color: AppColors.theme.mealTypeTextColor),
                textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('삭제'),
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteLogsTab extends StatelessWidget {
  const _DeleteLogsTab();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('admin_logs')
          .where('action', isEqualTo: 'delete_post')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text('삭제 로그가 없습니다',
                style: TextStyle(color: AppColors.theme.darkGreyColor)),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final adminName = data['adminName'] ?? '관리자';
            final postTitle = data['postTitle'] ?? '제목 없음';
            final postAuthorName = data['postAuthorName'] ?? '알 수 없음';
            final createdAt = data['createdAt'] as Timestamp?;
            final timeStr = createdAt != null
                ? '${createdAt.toDate().month}/${createdAt.toDate().day} ${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
                : '';

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
                          color: Colors.red.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('삭제', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(postTitle, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('작성자: $postAuthorName', style: TextStyle(
                      fontSize: 12, color: AppColors.theme.darkGreyColor)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text('삭제: $adminName', style: TextStyle(
                          fontSize: 12, color: AppColors.theme.primaryColor)),
                      const Spacer(),
                      Text(timeStr, style: TextStyle(
                          fontSize: 11, color: AppColors.theme.darkGreyColor)),
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

// ── 공용 위젯 ──

class _AdminSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final List<Widget> children;

  const _AdminSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.cardColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ],
          ),
        ),
        ...children,
      ],
    );
  }
}

class _AdminTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color cardColor;
  final bool initiallyExpanded;
  final Widget child;

  const _AdminTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.cardColor,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          collapsedBackgroundColor: cardColor,
          backgroundColor: cardColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(icon, size: 20, color: color),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color)),
          children: [child],
        ),
      ),
    );
  }
}

class _PopupNoticeManager extends StatefulWidget {
  final Color cardColor;
  const _PopupNoticeManager({required this.cardColor});

  @override
  State<_PopupNoticeManager> createState() => _PopupNoticeManagerState();
}

class _PopupNoticeManagerState extends State<_PopupNoticeManager> {
  bool _active = false;
  String _type = 'notice';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _dismissible = true;
  bool _loading = true;
  bool _saving = false;

  static const _types = ['emergency', 'notice', 'event'];
  static const _typeLabels = {'emergency': '긴급', 'notice': '공지', 'event': '이벤트'};
  static const _typeColors = {'emergency': Colors.red, 'notice': Color(0xFF3F72AF), 'event': Color(0xFF4CAF50)};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance.collection('app_config').doc('popup').get();
    if (doc.exists) {
      final d = doc.data()!;
      setState(() {
        _active = d['active'] ?? false;
        _type = d['type'] ?? 'notice';
        _titleController.text = d['title'] ?? '';
        _contentController.text = d['content'] ?? '';
        _startController.text = d['startDate'] ?? '';
        _endController.text = d['endDate'] ?? '';
        _dismissible = d['dismissible'] ?? true;
      });
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await FirebaseFirestore.instance.collection('app_config').doc('popup').set({
      'active': _active,
      'type': _type,
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'startDate': _startController.text.trim(),
      'endDate': _endController.text.trim(),
      'dismissible': _dismissible,
    });
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다')));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);

    if (_loading) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('팝업 활성화', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
              const Spacer(),
              Switch.adaptive(
                value: _active,
                activeColor: Colors.red,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: _types.map((t) {
              final selected = _type == t;
              final color = _typeColors[t] ?? AppColors.theme.primaryColor;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? color : AppColors.theme.darkGreyColor),
                    ),
                    child: Text(_typeLabels[t] ?? t, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.theme.darkGreyColor)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _titleController,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: '제목', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
              filled: true, fillColor: fillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _contentController,
            maxLines: 4,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: '내용', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
              filled: true, fillColor: fillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () => _pickDate(_startController),
                child: AbsorbPointer(child: TextField(
                  controller: _startController,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '시작일', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                    filled: true, fillColor: fillColor, prefixIcon: Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                )),
              )),
              const SizedBox(width: 8),
              Expanded(child: GestureDetector(
                onTap: () => _pickDate(_endController),
                child: AbsorbPointer(child: TextField(
                  controller: _endController,
                  style: TextStyle(color: textColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '종료일', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                    filled: true, fillColor: fillColor, prefixIcon: Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                )),
              )),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Text('"오늘 안 보기" 허용', style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor)),
              const Spacer(),
              Switch.adaptive(value: _dismissible, activeColor: AppColors.theme.primaryColor,
                onChanged: (v) => setState(() => _dismissible = v)),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _typeColors[_type] ?? Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('저장', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

