import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/chat/chat_room_screen.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// 채팅 목록 화면
///
/// - 내가 참여한 1:1 채팅 목록 표시
/// - 마지막 메시지 + 시간 + 읽지 않은 수 표시
/// - 탭하면 채팅방 진입
class ChatListScreen extends StatelessWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.currentUser?.uid;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('채팅')),
        body: const Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: const Text('채팅'),
        centerTitle: true,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: uid)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chat_outlined, size: 40, color: AppColors.theme.darkGreyColor),
                  const SizedBox(height: 8),
                  Text('채팅이 없습니다', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  const SizedBox(height: 4),
                  Text('게시글에서 사용자를 탭하면 채팅을 시작할 수 있어요',
                    style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor),
                    textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final participants = List<String>.from(data['participants'] ?? []);
              final names = Map<String, dynamic>.from(data['participantNames'] ?? {});
              final otherUid = participants.firstWhere((p) => p != uid, orElse: () => '');
              final otherName = names[otherUid] ?? '알 수 없음';
              final lastMessage = data['lastMessage'] ?? '';
              final lastMessageAt = data['lastMessageAt'] as Timestamp?;
              final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[uid] ?? 0;
              final timeStr = lastMessageAt != null ? _formatTime(lastMessageAt.toDate()) : '';

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(chatId: docs[index].id, otherName: otherName, otherUid: otherUid),
                )),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2028) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.theme.primaryColor,
                        child: Text(otherName.isNotEmpty ? otherName[0] : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(otherName, style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: textColor)),
                                const Spacer(),
                                Text(timeStr, style: TextStyle(
                                  fontSize: 11, color: AppColors.theme.darkGreyColor)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(lastMessage,
                                    style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text('$unreadCount',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return '방금';
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    if (diff.inDays < 7) return '${diff.inDays}일 전';
    return DateFormat('M/d').format(dt);
  }
}
