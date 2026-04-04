import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 1:1 채팅방 화면
///
/// - Firestore 실시간 메시지 스트림 (limit 30)
/// - 읽음 표시 (unreadCount 기반)
/// - 메시지 삭제 (나만/같이), 채팅방 나가기 (시스템 메시지)
/// - 시스템 메시지 렌더링
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String otherUid;

  const ChatRoomScreen({
    required this.chatId,
    required this.otherName,
    required this.otherUid,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'unreadCount.$uid': 0,
    });
  }

  void _showLeaveDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('채팅방을 나가시겠습니까?\n상대방에게 퇴장 메시지가 표시됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 22),
                title: const Text('채팅방 나가기', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.redAccent)),
                onTap: () { Navigator.pop(ctx); _leaveChat(); },
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leaveChat() async {
    try {
      final uid = AuthService.currentUser?.uid;
      if (uid == null) return;
      final profile = await AuthService.getCachedProfile();
      final myName = profile?.displayName ?? '알 수 없음';
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      await chatRef.collection('messages').add({
        'type': 'system',
        'content': '$myName님이 채팅방을 나갔습니다.',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await chatRef.update({
        'participants': FieldValue.arrayRemove([uid]),
        'lastMessage': '$myName님이 나갔습니다.',
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('채팅방 나가기에 실패했습니다')));
    }
  }

  void _showMessageActions(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final uid = AuthService.currentUser?.uid;
    if (data['type'] == 'system' || data['senderUid'] != uid) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final createdAt = data['createdAt'] as Timestamp?;
    final isWithinOneHour = createdAt != null && DateTime.now().difference(createdAt.toDate()).inMinutes < 60;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get(),
        builder: (context, chatSnap) {
          final chatData = chatSnap.data?.data() as Map<String, dynamic>?;
          final otherUnread = (chatData?['unreadCount'] as Map<String, dynamic>?)?[widget.otherUid] ?? 0;
          final canDeleteForAll = isWithinOneHour && (otherUnread as int) > 0;

          return Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : Colors.white, borderRadius: BorderRadius.circular(16)),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(width: 36, height: 4, decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: Icon(Icons.delete_outline, size: 22, color: isDark ? Colors.white70 : Colors.black87),
                    title: Text('나만 삭제', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                    onTap: () { Navigator.pop(ctx); _deleteForMe(doc.reference); },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  if (canDeleteForAll)
                    ListTile(
                      leading: const Icon(Icons.delete_forever, size: 22, color: Colors.redAccent),
                      title: const Text('같이 삭제', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.redAccent)),
                      onTap: () { Navigator.pop(ctx); _deleteForAll(doc.reference); },
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteForMe(DocumentReference ref) async {
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    await ref.update({'deletedFor': FieldValue.arrayUnion([uid])});
  }

  Future<void> _deleteForAll(DocumentReference ref) async {
    await ref.update({'content': '삭제된 메시지입니다.', 'deleted': true});
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final profile = await AuthService.getCachedProfile();
    final name = profile?.displayName ?? '';
    _controller.clear();
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
    await chatRef.collection('messages').add({
      'content': text, 'senderUid': uid, 'senderName': name,
      'createdAt': FieldValue.serverTimestamp(), 'deletedFor': [],
    });
    await chatRef.update({
      'lastMessage': text, 'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount.${widget.otherUid}': FieldValue.increment(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final uid = AuthService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: textColor,
        title: Text(widget.otherName), centerTitle: true, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.exit_to_app, size: 22), tooltip: '나가기', onPressed: _showLeaveDialog),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, chatSnapshot) {
                final chatData = chatSnapshot.data?.data();
                final otherUnread = (chatData?['unreadCount'] as Map<String, dynamic>?)?[widget.otherUid] ?? 0;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId)
                      .collection('messages').orderBy('createdAt', descending: true).limit(30).snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return Center(child: Text('첫 메시지를 보내보세요', style: TextStyle(color: AppColors.theme.darkGreyColor)));

                    return ListView.builder(
                      controller: _scrollController, reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                        if (deletedFor.contains(uid)) return const SizedBox.shrink();

                        if (data['type'] == 'system') {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF252830) : const Color(0xFFE8E8E8),
                                borderRadius: BorderRadius.circular(12)),
                              child: Text(data['content'] ?? '', style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                            )),
                          );
                        }

                        final isMe = data['senderUid'] == uid;
                        final content = data['content'] ?? '';
                        final isDeleted = data['deleted'] == true;
                        final createdAt = data['createdAt'] as Timestamp?;
                        final timeStr = createdAt != null
                            ? '${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}' : '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GestureDetector(
                            onLongPress: (isMe && !isDeleted) ? () => _showMessageActions(doc) : null,
                            child: Row(
                              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isMe) ...[
                                  Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                                    if (!isDeleted && (otherUnread as int) == 0)
                                      Text('읽음', style: TextStyle(fontSize: 9, color: AppColors.theme.primaryColor, fontWeight: FontWeight.w600)),
                                    Text(timeStr, style: TextStyle(fontSize: 10, color: AppColors.theme.darkGreyColor)),
                                  ]),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDeleted
                                        ? (isDark ? const Color(0xFF1A1C22) : const Color(0xFFE8E8E8))
                                        : isMe ? AppColors.theme.primaryColor
                                            : (isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0)),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16), topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4), bottomRight: Radius.circular(isMe ? 4 : 16)),
                                  ),
                                  child: Text(content, style: TextStyle(fontSize: 14,
                                    fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                    color: isDeleted ? AppColors.theme.darkGreyColor : isMe ? Colors.white : textColor)),
                                ),
                                if (!isMe) ...[
                                  const SizedBox(width: 6),
                                  Text(timeStr, style: TextStyle(fontSize: 10, color: AppColors.theme.darkGreyColor)),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2028) : Colors.white,
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA)))),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _controller,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요', hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                  filled: true, fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                onSubmitted: (_) => _sendMessage(),
              )),
              const SizedBox(width: 4),
              IconButton(onPressed: _sendMessage, icon: Icon(Icons.send, color: AppColors.theme.primaryColor)),
            ]),
          ),
        ],
      ),
    );
  }
}
