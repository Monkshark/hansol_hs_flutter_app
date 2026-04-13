# ChatUtils

> `lib/screens/chat/chat_utils.dart` — 1:1 채팅 시작 유틸리티

---

## `startChat`

```dart
Future<void> startChat(BuildContext context, String otherUid, String otherName)
```

**설명**: 두 유저 간 1:1 채팅방을 열거나 생성함

### 실행 흐름

1. **미로그인 체크**: `myUid == null` → early return (로그인 필수)
2. **자기 자신 방지**: `myUid == otherUid` → early return
3. **결정론적 chatId 생성** (uid 정렬):
   ```dart
   String _getChatId(String uid1, String uid2) {
     final sorted = [uid1, uid2]..sort();
     return '${sorted[0]}_${sorted[1]}';
   }
   ```
4. **프로필 조회**: `AuthService.getCachedProfile()`로 내 이름 가져옴
5. **기존 채팅방 확인**: Firestore `chats/{chatId}` 문서 get
6. **없으면 새로 생성**:
   ```dart
   await chatRef.set({
     'participants': [myUid, otherUid],
     'participantNames': {myUid: myName, otherUid: otherName},
     'lastMessage': '',
     'lastMessageAt': FieldValue.serverTimestamp(),
     'unreadCount': {myUid: 0, otherUid: 0},
   });
   ```
7. **`context.mounted` 체크 후** `ChatRoomScreen`으로 이동

### 엣지 케이스

| 상황 | 처리 |
|------|------|
| 미로그인 상태 | `currentUser?.uid`가 null → silent return |
| 자기 자신에게 채팅 시도 | uid 비교로 차단 |
| 기존 채팅방이 이미 존재 | 생성 스킵, 기존 방으로 이동 |
| 채팅방 생성 중 async gap | `context.mounted` 체크 후 네비게이션 |
| 상대방 이름 변경됨 | `participantNames`는 생성 시 snapshot — 실시간 반영 안 됨 (known limitation) |
| 동시에 양쪽에서 채팅 시작 | `chatId`가 결정론적이므로 같은 문서 참조 → `set`이 idempotent하게 작동 (둘 다 같은 구조 write) |
| 익명 게시글 작성자 | **호출부에서 차단** — 익명 글의 "1:1 채팅" 버튼을 숨김 |
| 탈퇴한 유저와의 채팅 | 채팅방은 남아있되, 상대 프로필 조회 실패 시 이름이 빈 문자열로 표시 |

### `_getChatId` — 결정론적 ID

```dart
String _getChatId(String uid1, String uid2) {
  final sorted = [uid1, uid2]..sort();
  return '${sorted[0]}_${sorted[1]}';
}
```

두 uid를 사전순 정렬 후 `_`로 결합. A→B 채팅과 B→A 채팅이 항상 같은 문서 ID를 가리킴 → 중복 채팅방 방지

**호출 위치**: 게시글 작성자 프로필 탭 → "1:1 채팅" 버튼, 채팅 목록 → 유저 검색
