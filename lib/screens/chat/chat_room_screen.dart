import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 1:1 채팅방 화면
///
/// - Firestore 실시간 메시지 스트림
/// - 메시지 입력 + 전송
/// - 읽음 처리 (입장 시 unreadCount 리셋)
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
      'content': text,
      'senderUid': uid,
      'senderName': name,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatRef.update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
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
        title: Text(widget.otherName),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text('첫 메시지를 보내보세요',
                      style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final isMe = data['senderUid'] == uid;
                    final content = data['content'] ?? '';
                    final createdAt = data['createdAt'] as Timestamp?;
                    final timeStr = createdAt != null
                        ? '${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}'
                        : '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isMe) ...[
                            Text(timeStr, style: TextStyle(fontSize: 10, color: AppColors.theme.darkGreyColor)),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.65),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? AppColors.theme.primaryColor
                                  : (isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Text(content, style: TextStyle(
                              fontSize: 14,
                              color: isMe ? Colors.white : textColor,
                            )),
                          ),
                          if (!isMe) ...[
                            const SizedBox(width: 6),
                            Text(timeStr, style: TextStyle(fontSize: 10, color: AppColors.theme.darkGreyColor)),
                          ],
                        ],
                      ),
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
              border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: _sendMessage,
                  icon: Icon(Icons.send, color: AppColors.theme.primaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
