import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class UsersTab extends StatefulWidget {
  final String filter;
  const UsersTab({required this.filter});

  @override
  State<UsersTab> createState() => UsersTabState();
}

class UsersTabState extends State<UsersTab> {
  late Future<QuerySnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetch() =>
      FirebaseFirestore.instance.collection('users').get();

  void _refresh() => setState(() => _future = _fetch());

  Future<void> _logAdminAction(String action, String targetUid, String targetName) async {
    await FirebaseFirestore.instance.collection('admin_logs').add({
      'action': action,
      'targetUid': targetUid,
      'targetName': targetName,
      'adminUid': AuthService.currentUser?.uid ?? '',
      'adminName': AuthService.cachedProfile?.displayName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))),
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

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((d) {
          final data = d.data();
          final approved = data['approved'] == true;
          final suspended = _isSuspended(data);

          switch (widget.filter) {
            case 'pending': return !approved;
            case 'approved':
              if (!approved) return false;
              if (suspended) return false;
              return true;
            case 'suspended': return approved && suspended;
            default: return false;
          }
        }).toList();

        if (widget.filter == 'approved') {
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text(emptyMsg[widget.filter] ?? '',
              style: TextStyle(color: AppColors.theme.darkGreyColor))),
          );
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
                                if (widget.filter == 'suspended') ...[
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
                          if (widget.filter == 'pending') ...[
                            _actionBtn('승인', AppColors.theme.primaryColor, () async {
                              await docs[index].reference.update({'approved': true});
                              await _sendAccountNotification(uid, '가입 승인', '가입이 승인되었습니다.');
                              await _logAdminAction('승인', uid, name);
                              _refresh();
                            }),
                            const SizedBox(width: 6),
                            _actionBtn('거절', Colors.red, () async {
                              await _sendAccountNotification(uid, '가입 거절', '가입이 거절되었습니다.');
                              await docs[index].reference.delete();
                              await _logAdminAction('거절', uid, name);
                              _refresh();
                            }),
                          ],
                          if (widget.filter == 'approved') ...[
                            if (isAdmin && role == 'admin' && uid == AuthService.currentUser?.uid)
                              _actionBtn('Admin 해제', AppColors.theme.darkGreyColor, () async {
                                await docs[index].reference.update({'role': 'user'});
                                AuthService.clearProfileCache();
                                _refresh();
                              }),
                            if (isAdmin && role != 'admin') ...[
                              _actionBtn(
                                role == 'manager' ? '매니저 해제' : '매니저',
                                role == 'manager' ? AppColors.theme.darkGreyColor : AppColors.theme.secondaryColor,
                                () async {
                                  final newRole = role == 'manager' ? 'user' : 'manager';
                                  await docs[index].reference.update({'role': newRole});
                                  await _logAdminAction('역할 변경: $newRole', uid, name);
                                  _refresh();
                                },
                              ),
                              const SizedBox(width: 6),
                              _actionBtn('Admin', Colors.red, () async {
                                await docs[index].reference.update({'role': 'admin'});
                                await _logAdminAction('역할 변경: admin', uid, name);
                                _refresh();
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
                                  _refresh();
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
                                  _refresh();
                                }
                              }),
                            ],
                          ],
                          if (widget.filter == 'suspended') ...[
                            _actionBtn('정지 해제', AppColors.theme.primaryColor, () async {
                              await docs[index].reference.update({'suspendedUntil': null});
                              await _sendAccountNotification(uid, '정지 해제', '계정 정지가 해제되었습니다.');
                              await _logAdminAction('정지 해제', uid, name);
                              _refresh();
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
