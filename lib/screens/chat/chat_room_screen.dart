import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hansol_high_school/widgets/error_snackbar.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/analytics_service.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/data/image_utils.dart';
import 'package:hansol_high_school/data/input_sanitizer.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/widgets/error_view.dart';
import 'package:image_picker/image_picker.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherName;
  final String otherUid;

  const ChatRoomScreen({
    required this.chatId,
    required this.otherName,
    required this.otherUid,
    super.key,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackFirstVisit('chat');
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
                child: Text(AppLocalizations.of(context)!.chat_leaveConfirmationRoom,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.5)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent, size: 22),
                title: Text(AppLocalizations.of(context)!.chat_leaveAction, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.redAccent)),
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
      if (!mounted) return;
      final myName = profile?.displayName ?? AppLocalizations.of(context)!.chat_unknownUser;
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      await chatRef.collection('messages').add({
        'type': 'system',
        'content': AppLocalizations.of(context)!.chat_leftMessage(myName),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      await chatRef.update({
        'participants': FieldValue.arrayRemove([uid]),
        'lastMessage': AppLocalizations.of(context)!.chat_leftShort(myName),
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      log('ChatRoom: leave error: $e');
      if (mounted) showErrorSnackbar(context, e);
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
          if (chatSnap.hasError) return const SizedBox.shrink();
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
                    title: Text(AppLocalizations.of(context)!.chat_deleteForMe, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                    onTap: () { Navigator.pop(ctx); _deleteForMe(doc.reference); },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  if (canDeleteForAll)
                    ListTile(
                      leading: const Icon(Icons.delete_forever, size: 22, color: Colors.redAccent),
                      title: Text(AppLocalizations.of(context)!.chat_deleteForAll, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.redAccent)),
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
    try {
      await ref.update({'deletedFor': FieldValue.arrayUnion([uid])});
    } catch (e) {
      log('ChatRoomScreen: deleteForMe error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Future<void> _deleteForAll(DocumentReference ref) async {
    try {
      await ref.update({'content': AppLocalizations.of(context)!.chat_deletedMessage, 'deleted': true});
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      if (!mounted) return;
      await chatRef.update({'lastMessage': AppLocalizations.of(context)!.chat_deletedMessage});
    } catch (e) {
      log('ChatRoomScreen: deleteForAll error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  void _showImageViewer(String url) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: InteractiveViewer(
            child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
          ),
        ),
      ),
    ));
  }

  Future<void> _sendMessage() async {
    final text = InputSanitizer.sanitize(_controller.text.trim());
    if (text.isEmpty) return;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;
    final profile = await AuthService.getCachedProfile();
    final name = profile?.displayName ?? '';
    _controller.clear();
    try {
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      await chatRef.collection('messages').add({
        'content': text, 'senderUid': uid, 'senderName': name,
        'createdAt': FieldValue.serverTimestamp(), 'deletedFor': [],
      });
      await chatRef.update({
        'lastMessage': text, 'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.${widget.otherUid}': FieldValue.increment(1),
      });
    } catch (e) {
      log('ChatRoomScreen: sendMessage error: $e');
      if (mounted) showErrorSnackbar(context, e);
    }
  }

  Future<void> _sendImage() async {
    if (_uploadingImage) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final uid = AuthService.currentUser?.uid;
    if (uid == null) return;

    setState(() => _uploadingImage = true);
    try {
      final compressed = await ImageUtils.compress(File(picked.path), minWidth: 1280);
      final fileToUpload = compressed ?? File(picked.path);

      final ref = FirebaseStorage.instance.ref(
        'chats/${widget.chatId}/${DateTime.now().millisecondsSinceEpoch}_$uid.jpg',
      );
      await ref.putFile(fileToUpload);
      final url = await ref.getDownloadURL();

      final profile = await AuthService.getCachedProfile();
      final name = profile?.displayName ?? '';
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(widget.chatId);
      await chatRef.collection('messages').add({
        'content': '', 'imageUrl': url, 'senderUid': uid, 'senderName': name,
        'createdAt': FieldValue.serverTimestamp(), 'deletedFor': [],
      });
      if (!mounted) return;
      await chatRef.update({
        'lastMessage': AppLocalizations.of(context)!.chat_imageCaption, 'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount.${widget.otherUid}': FieldValue.increment(1),
      });
    } catch (e) {
      log('ChatRoom: image send error: $e');
      if (mounted) showErrorSnackbar(context, e);
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
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
          IconButton(icon: const Icon(Icons.exit_to_app, size: 22), tooltip: AppLocalizations.of(context)!.chat_leaveButton, onPressed: _showLeaveDialog),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).snapshots(),
              builder: (context, chatSnapshot) {
                if (chatSnapshot.hasError) {
                  return ErrorView(message: AppLocalizations.of(context)!.error_loadFailed);
                }
                final chatData = chatSnapshot.data?.data();
                final otherUnread = (chatData?['unreadCount'] as Map<String, dynamic>?)?[widget.otherUid] ?? 0;

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId)
                      .collection('messages').orderBy('createdAt', descending: true).limit(30).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return ErrorView(message: AppLocalizations.of(context)!.error_loadFailed);
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) return Center(child: Text(AppLocalizations.of(context)!.chat_firstMessage, style: TextStyle(color: AppColors.theme.darkGreyColor)));

                    int myUnreadRemaining = (otherUnread as int?) ?? 0;

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
                        final imageUrl = data['imageUrl']?.toString();
                        final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                        final isDeleted = data['deleted'] == true;
                        final createdAt = data['createdAt'] as Timestamp?;
                        final timeStr = createdAt != null
                            ? '${createdAt.toDate().hour}:${createdAt.toDate().minute.toString().padLeft(2, '0')}' : '';

                        bool showRead = false;
                        if (isMe && !isDeleted) {
                          if (myUnreadRemaining > 0) {
                            myUnreadRemaining--;
                          } else {
                            showRead = true;
                          }
                        }

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
                                    if (showRead)
                                      Text(AppLocalizations.of(context)!.chat_read, style: TextStyle(fontSize: 9, color: AppColors.theme.primaryColor, fontWeight: FontWeight.w600)),
                                    Text(timeStr, style: TextStyle(fontSize: 10, color: AppColors.theme.darkGreyColor)),
                                  ]),
                                  const SizedBox(width: 6),
                                ],
                                if (hasImage && !isDeleted)
                                  ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    child: GestureDetector(
                                      onTap: () => _showImageViewer(imageUrl),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        width: MediaQuery.of(context).size.width * 0.55,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 600,
                                        placeholder: (_, __) => Container(
                                          width: MediaQuery.of(context).size.width * 0.55,
                                          height: MediaQuery.of(context).size.height * 0.2,
                                          color: isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0),
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: MediaQuery.of(context).size.width * 0.55,
                                          height: MediaQuery.of(context).size.height * 0.12,
                                          color: isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0),
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                  )
                                else
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
              IconButton(
                onPressed: _uploadingImage ? null : _sendImage,
                icon: _uploadingImage
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.image_outlined, color: AppColors.theme.primaryColor),
                tooltip: AppLocalizations.of(context)!.chat_sendImage,
              ),
              Expanded(child: TextField(
                controller: _controller,
                style: TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.chat_messagePlaceholder, hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                  filled: true, fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                onSubmitted: (_) => _sendMessage(),
              )),
              const SizedBox(width: 4),
              IconButton(onPressed: _sendMessage, tooltip: 'Send message', icon: Icon(Icons.send, color: AppColors.theme.primaryColor)),
            ]),
          ),
        ],
      ),
    );
  }
}
