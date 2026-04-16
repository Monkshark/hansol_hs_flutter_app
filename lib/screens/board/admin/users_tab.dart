import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/error_snackbar.dart';

class UsersTab extends StatefulWidget {
  final String filter;
  final VoidCallback? onChanged;
  const UsersTab({super.key, required this.filter, this.onChanged});

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

  void refresh() => setState(() => _future = _fetch());

  void _refreshAll() {
    refresh();
    widget.onChanged?.call();
  }

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

  String _suspendRemaining(BuildContext context, Timestamp ts) {
    final l = AppLocalizations.of(context)!;
    final diff = ts.toDate().difference(DateTime.now());
    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final parts = <String>[];
    if (d > 0) parts.add(l.admin_usersDaysLeft(d));
    if (h > 0) parts.add(l.admin_usersHoursLeft(h));
    if (m > 0) parts.add(l.admin_usersMinutesLeft(m));
    return parts.isEmpty ? l.admin_usersLessThan1Minute : parts.join(' ');
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
        if (snapshot.hasError) {
          return const Center(child: Text('오류가 발생했습니다'));
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

        final l = AppLocalizations.of(context)!;
        final emptyMsg = {
          'pending': l.admin_usersNoPending,
          'approved': l.admin_usersNoApproved,
          'suspended': l.admin_usersNoSuspended,
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
            if (myProfileSnap.hasError) {
              return const Center(child: Text('오류가 발생했습니다'));
            }
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
                                        child: Text(l.admin_usersMakeManager, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.theme.secondaryColor)),
                                      ),
                                    ],
                                  ],
                                ),
                                Text('$studentId · $grade학년 $classNum반',
                                  style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                                if (widget.filter == 'suspended') ...[
                                  const SizedBox(height: 4),
                                  Text(l.admin_usersSuspendedRemaining(_suspendRemaining(context, data['suspendedUntil'] as Timestamp)),
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
                            _actionBtn(l.admin_usersApprove, AppColors.theme.primaryColor, () async {
                              try {
                                await docs[index].reference.update({'approved': true});
                                await _sendAccountNotification(uid, l.admin_usersAccountApproved, l.admin_usersApprovedMessage);
                                await _logAdminAction('승인', uid, name);
                                _refreshAll();
                              } catch (e) {
                                log('UsersTab: approve error: $e');
                                if (context.mounted) showErrorSnackbar(context, e);
                              }
                            }),
                            const SizedBox(width: 6),
                            _actionBtn(l.admin_usersReject, Colors.red, () async {
                              try {
                                await _sendAccountNotification(uid, l.admin_usersAccountRejected, l.admin_usersRejectedMessage);
                                await docs[index].reference.delete();
                                await _logAdminAction('거절', uid, name);
                                _refreshAll();
                              } catch (e) {
                                log('UsersTab: reject error: $e');
                                if (context.mounted) showErrorSnackbar(context, e);
                              }
                            }),
                          ],
                          if (widget.filter == 'approved') ...[
                            if (isAdmin && role == 'admin' && uid == AuthService.currentUser?.uid)
                              _actionBtn(l.admin_usersRemoveAdmin, AppColors.theme.darkGreyColor, () async {
                                try {
                                  await docs[index].reference.update({'role': 'user'});
                                  AuthService.clearProfileCache();
                                  _refreshAll();
                                } catch (e) {
                                  log('UsersTab: removeAdmin error: $e');
                                  if (context.mounted) showErrorSnackbar(context, e);
                                }
                              }),
                            if (isAdmin && role != 'admin') ...[
                              _actionBtn(
                                role == 'manager' ? l.admin_usersRemoveManager : l.admin_usersMakeManager,
                                role == 'manager' ? AppColors.theme.darkGreyColor : AppColors.theme.secondaryColor,
                                () async {
                                  try {
                                    final newRole = role == 'manager' ? 'user' : 'manager';
                                    await docs[index].reference.update({'role': newRole});
                                    await _logAdminAction('역할 변경: $newRole', uid, name);
                                    _refreshAll();
                                  } catch (e) {
                                    log('UsersTab: roleChange error: $e');
                                    if (context.mounted) showErrorSnackbar(context, e);
                                  }
                                },
                              ),
                              const SizedBox(width: 6),
                              _actionBtn('Admin', Colors.red, () async {
                                try {
                                  await docs[index].reference.update({'role': 'admin'});
                                  await _logAdminAction('역할 변경: admin', uid, name);
                                  _refreshAll();
                                } catch (e) {
                                  log('UsersTab: makeAdmin error: $e');
                                  if (context.mounted) showErrorSnackbar(context, e);
                                }
                              }),
                            ],
                            if (uid != AuthService.currentUser?.uid && role == 'user') ...[
                              const SizedBox(width: 6),
                              _actionBtn(l.admin_usersSuspend, Colors.orange, () async {
                                final hours = await _showSuspendDialog(context, name);
                                if (hours != null) {
                                  try {
                                    final until = DateTime.now().add(Duration(hours: hours));
                                    await docs[index].reference.update({'suspendedUntil': Timestamp.fromDate(until)});
                                    if (!context.mounted) return;
                                    await _sendAccountNotification(uid, l.admin_usersAccountSuspended, l.admin_usersSuspendedMessage(_formatDuration(context, hours)));
                                    await _logAdminAction('정지', uid, name);
                                    _refreshAll();
                                  } catch (e) {
                                    log('UsersTab: suspend error: $e');
                                    if (context.mounted) showErrorSnackbar(context, e);
                                  }
                                }
                              }),
                              const SizedBox(width: 6),
                              _actionBtn(l.admin_usersDelete, Colors.red, () async {
                                final first = await _confirmDialog(context, l.admin_usersDeleteConfirm, l.admin_usersDeleteConfirmMessage(name));
                                if (first != true || !context.mounted) return;
                                final second = await _confirmDialog(context, l.admin_usersDeleteFinal, l.admin_usersDeleteFinalMessage(name));
                                if (!context.mounted) return;
                                if (second == true) {
                                  try {
                                    await _sendAccountNotification(uid, l.admin_usersAccountDeleted, l.admin_usersDeletedMessage);
                                    await docs[index].reference.delete();
                                    await _logAdminAction('삭제', uid, name);
                                    _refreshAll();
                                  } catch (e) {
                                    log('UsersTab: delete error: $e');
                                    if (context.mounted) showErrorSnackbar(context, e);
                                  }
                                }
                              }),
                            ],
                          ],
                          if (widget.filter == 'suspended') ...[
                            _actionBtn(l.admin_usersUnsuspend, AppColors.theme.primaryColor, () async {
                              try {
                                await docs[index].reference.update({'suspendedUntil': null});
                                await _sendAccountNotification(uid, l.admin_usersSuspendRemoved, l.admin_usersSuspendRemovedMessage);
                                await _logAdminAction('정지 해제', uid, name);
                                _refreshAll();
                              } catch (e) {
                                log('UsersTab: unsuspend error: $e');
                                if (context.mounted) showErrorSnackbar(context, e);
                              }
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

  String _formatDuration(BuildContext context, int hours) {
    final l = AppLocalizations.of(context)!;
    if (hours < 24) return l.admin_usersHoursLeft(hours);
    return l.admin_usersDaysLeft(hours ~/ 24);
  }

  Future<int?> _showSuspendDialog(BuildContext context, String name) async {
    final l = AppLocalizations.of(context)!;
    final options = [
      {'label': l.admin_usersSuspend1Hour, 'hours': 1},
      {'label': l.admin_usersSuspend6Hours, 'hours': 6},
      {'label': l.admin_usersSuspend12Hours, 'hours': 12},
      {'label': l.admin_usersSuspend1Day, 'hours': 24},
      {'label': l.admin_usersSuspend3Days, 'hours': 72},
      {'label': l.admin_usersSuspend7Days, 'hours': 168},
      {'label': l.admin_usersSuspend30Days, 'hours': 720},
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
              Text(l.admin_usersSuspendTitle(name), style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: Theme.of(ctx).textTheme.bodyLarge?.color)),
              const SizedBox(height: 8),
              Text(l.admin_usersSuspendSelectDuration, style: TextStyle(
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
                child: Text(l.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
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
    } catch (e) {
      log('UsersTab: send notification error: $e');
    }
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
                    child: Text(AppLocalizations.of(context)!.common_cancel, style: TextStyle(color: AppColors.theme.darkGreyColor)),
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
                    child: Text(AppLocalizations.of(context)!.admin_usersDelete),
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
