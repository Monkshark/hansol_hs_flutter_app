import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/chat/chat_room_screen.dart';
import 'package:hansol_high_school/screens/chat/chat_utils.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/skeleton.dart';
import 'package:intl/intl.dart';

/// 채팅 목록 화면
///
/// - 내가 참여한 1:1 채팅 목록 표시
/// - 마지막 메시지 + 시간 + 읽지 않은 수 표시
/// - 길게 누르면 채팅방 나가기
/// - 스켈레톤 로딩 UI
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {

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
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, size: 22),
            tooltip: '새 채팅',
            onPressed: () => _showUserSearch(context, uid),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: uid)
            .orderBy('lastMessageAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ChatListSkeleton();
          }
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
                onLongPress: () => _showLeaveDialog(docs[index].id, otherName),
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

  void _showUserSearch(BuildContext context, String myUid) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchController = TextEditingController();
    List<Map<String, dynamic>> results = [];
    List<Map<String, dynamic>> admins = [];
    List<Map<String, dynamic>> allUsers = [];
    bool loaded = false;

    Future<void> loadUsers(void Function(void Function()) setSheetState) async {
      if (loaded) return;
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('approved', isEqualTo: true).get();
      allUsers = snap.docs.where((d) => d.id != myUid).map((d) => {'uid': d.id, ...d.data()}).toList();
      admins = allUsers.where((u) => u['role'] == 'admin' || u['role'] == 'manager').toList();
      loaded = true;
      setSheetState(() {});
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          if (!loaded) loadUsers(setSheetState);
          return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2028) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: '이름 또는 학번으로 검색',
                    hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                    prefixIcon: Icon(Icons.search, color: AppColors.theme.darkGreyColor),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (query) {
                    if (query.trim().length < 2) {
                      setSheetState(() => results = []);
                      return;
                    }
                    final q = query.trim().toLowerCase();
                    final filtered = allUsers.where((u) {
                      final name = (u['name'] ?? '').toString().toLowerCase();
                      final sid = (u['studentId'] ?? '').toString().toLowerCase();
                      return name.contains(q) || sid.contains(q);
                    }).toList();
                    setSheetState(() => results = filtered);
                  },
                ),
              ),
              Expanded(
                child: _buildUserList(context, searchController.text.trim().length >= 2 ? results : admins,
                  searchController.text.trim().length >= 2, ctx),
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  Widget _buildUserList(BuildContext context, List<Map<String, dynamic>> list, bool isSearch, BuildContext sheetCtx) {
    if (list.isEmpty) {
      return Center(child: Text(
        isSearch ? '검색 결과가 없습니다' : '관리자를 불러오는 중...',
        style: TextStyle(color: AppColors.theme.darkGreyColor)));
    }
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, index) {
        final user = list[index];
        final name = user['name'] ?? '';
        final sid = user['studentId'] ?? '';
        final userType = user['userType'] ?? 'student';
        final role = user['role'] ?? 'user';

        String displayName;
        switch (userType) {
          case 'teacher': displayName = '교사 $name'; break;
          case 'parent': displayName = '학부모 $name'; break;
          case 'graduate': displayName = '졸업생 $name'; break;
          default: displayName = sid.isNotEmpty ? '$sid $name' : name;
        }

        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.theme.primaryColor,
            child: Text(name.isNotEmpty ? name[0] : '?',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          title: Row(children: [
            Text(displayName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color)),
            if (role == 'admin' || role == 'manager') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: role == 'admin' ? Colors.red.withAlpha(25) : AppColors.theme.primaryColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(role == 'admin' ? 'Admin' : '매니저',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700,
                    color: role == 'admin' ? Colors.red : AppColors.theme.primaryColor)),
              ),
            ],
          ]),
          subtitle: userType == 'teacher' && (user['teacherSubject'] ?? '').isNotEmpty
              ? Text(user['teacherSubject'], style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor))
              : null,
          onTap: () {
            Navigator.pop(sheetCtx);
            startChat(context, user['uid'], displayName);
          },
        );
      },
    );
  }

  void _showLeaveDialog(String chatId, String otherName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E2028) : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('$otherName 님과의 채팅방을 나가시겠습니까?\n상대방에게 퇴장 메시지가 표시됩니다.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 22),
            title: const Text('채팅방 나가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.redAccent)),
            onTap: () { Navigator.pop(ctx); _leaveChat(chatId); },
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 8),
        ])),
      ),
    );
  }

  Future<void> _leaveChat(String chatId) async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;
      final profile = await AuthService.getCachedProfile();
      final myName = profile?.displayName ?? '알 수 없음';
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      await chatRef.collection('messages').add({
        'type': 'system', 'content': '$myName님이 채팅방을 나갔습니다.', 'createdAt': FieldValue.serverTimestamp(),
      });
      await chatRef.update({
        'participants': FieldValue.arrayRemove([uid]),
        'lastMessage': '$myName님이 나갔습니다.', 'lastMessageAt': FieldValue.serverTimestamp(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅방을 나갔습니다')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅방 나가기에 실패했습니다')));
    }
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
