# ChatUtils

> `lib/screens/chat/chat_utils.dart` — 1:1 채팅 시작 유틸리티

---

## `startChat`

```dart
Future<void> startChat(BuildContext context, String otherUid, String otherName)
```

**설명**: 두 유저 간 1:1 채팅방을 열거나 생성함

1. 자기 자신과의 채팅 방지:
   ```dart
   if (myUid == otherUid) return;
   ```

2. 결정론적 chatId 생성 (uid 정렬):
   ```dart
   String _getChatId(String uid1, String uid2) {
     final sorted = [uid1, uid2]..sort();
     return '${sorted[0]}_${sorted[1]}';
   }
   ```

3. 기존 채팅방 확인, 없으면 새로 생성:
   ```dart
   final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
   final snap = await chatRef.get();
   if (!snap.exists) {
     await chatRef.set({
       'participants': [myUid, otherUid],
       'participantNames': {myUid: myName, otherUid: otherName},
       'lastMessage': '',
       'lastMessageAt': FieldValue.serverTimestamp(),
       'unreadCount': {myUid: 0, otherUid: 0},
     });
   }
   ```

4. `ChatRoomScreen`으로 이동:
   ```dart
   Navigator.push(context, MaterialPageRoute(
     builder: (_) => ChatRoomScreen(chatId: chatId, otherName: otherName, otherUid: otherUid),
   ));
   ```

**참고**: 게시글 작성자 프로필 탭 → "1:1 채팅" 버튼에서 호출됨. 익명 게시글의 경우 호출부에서 차단
