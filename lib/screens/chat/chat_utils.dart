import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/auth_service.dart';
import 'package:hansol_high_school/screens/chat/chat_room_screen.dart';

/// 1:1 채팅 시작 유틸리티
///
/// - 두 유저 간 기존 채팅방 조회 또는 새로 생성
/// - 익명 사용자끼리는 채팅 불가
Future<void> startChat(BuildContext context, String otherUid, String otherName) async {
  final myUid = AuthService.currentUser?.uid;
  if (myUid == null) return;
  if (myUid == otherUid) return;

  final chatId = _getChatId(myUid, otherUid);
  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
  final snap = await chatRef.get();

  final myProfile = await AuthService.getCachedProfile();
  final myName = myProfile?.displayName ?? '';

  if (!snap.exists) {
    await chatRef.set({
      'participants': [myUid, otherUid],
      'participantNames': {myUid: myName, otherUid: otherName},
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCount': {myUid: 0, otherUid: 0},
    });
  }

  if (context.mounted) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatRoomScreen(chatId: chatId, otherName: otherName, otherUid: otherUid),
    ));
  }
}

String _getChatId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return '${sorted[0]}_${sorted[1]}';
}
