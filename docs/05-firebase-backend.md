# Firebase 백엔드 상세 가이드

---

## Firestore 컬렉션 구조

### users/{uid}

사용자 프로필 및 설정

```
users/{uid}
├── name: string                    # 이름
├── studentId: string               # 학번 ("20301")
├── grade: number                   # 학년
├── classNum: number                # 반
├── email: string                   # 이메일
├── approved: boolean               # 관리자 승인 여부
├── role: string                    # "user" | "manager" | "admin"
├── userType: string                # "student" | "graduate" | "teacher" | "parent"
├── lastProfileUpdate: string       # 마지막 업데이트 연도 ("2026")
├── graduationYear: number?         # 졸업생: 졸업연도
├── teacherSubject: string?         # 교사: 담당과목
├── suspendedUntil: timestamp?      # 정지 만료 시각
├── blockedUsers: array<string>     # 차단한 UID 목록
├── loginProvider: string           # "google" | "apple" | "kakao" | "github"
├── profilePhotoUrl: string?        # 프로필 사진 URL
├── fcmToken: string?               # FCM 푸시 토큰
├── notiComment: boolean            # 댓글 알림 (기본 true)
├── notiReply: boolean              # 대댓글 알림 (기본 true)
├── notiMention: boolean            # 멘션 알림 (기본 true)
├── notiChat: boolean               # 채팅 알림 (기본 true)
├── notiAccount: boolean            # 계정 알림 (기본 true)
│
├── subjects/                       # 서브컬렉션: 선택과목
│   └── grade_{n}/
│       ├── subjects: array<Subject>
│       └── updatedAt: timestamp
│
├── notifications/                  # 서브컬렉션: 알림
│   └── {notifId}/
│       ├── type: string            # "comment" | "reply" | "account"
│       ├── postId: string
│       ├── postTitle: string
│       ├── senderName: string
│       ├── content: string
│       ├── read: boolean
│       └── createdAt: timestamp
│
└── sync/                           # 서브컬렉션: 데이터 동기화
    ├── ddays/
    │   └── items: array<DDay>
    └── schedules/
        └── items: array<Schedule>
```

### posts/{postId}

게시판 글

```
posts/{postId}
├── title: string                   # 제목 (1~200자)
├── content: string                 # 본문 (0~5000자)
├── category: string                # "자유" | "질문" | "정보공유" | "분실물" | "학생회" | "동아리"
├── authorUid: string               # 작성자 UID
├── authorName: string              # 작성자 이름
├── isAnonymous: boolean            # 익명 여부
├── createdAt: timestamp            # 작성 시각
├── updatedAt: timestamp?           # 수정 시각
│
├── likes: map<string, boolean>     # UID → true (좋아요)
├── dislikes: map<string, boolean>  # UID → true (싫어요)
├── likeCount: number               # 좋아요 수 (비정규화)
├── dislikeCount: number            # 싫어요 수 (비정규화)
├── commentCount: number            # 댓글 수 (비정규화)
│
├── bookmarkedBy: array<string>     # 북마크한 UID 목록
├── searchTokens: array<string>     # 2-gram 검색 토큰
├── imageUrls: array<string>        # 이미지 URL 목록
│
├── isPinned: boolean               # 고정글 여부
├── pinnedAt: timestamp?            # 고정 시각
│
├── pollOptions: array<string>?     # 투표 옵션
├── pollVoters: map<string, number>?# UID → 선택 인덱스
│
├── eventDate: string?              # 첨부 일정 날짜
├── eventStartTime: string?         # 시작 시간
├── eventEndTime: string?           # 종료 시간
├── eventContent: string?           # 일정 내용
│
├── anonymousMapping: map<string, number>  # UID → 익명 번호
├── anonymousCount: number                 # 다음 익명 번호
│
└── comments/                       # 서브컬렉션: 댓글
    └── {commentId}/
        ├── content: string         # 댓글 내용 (1~1000자)
        ├── authorUid: string
        ├── authorName: string
        ├── isAnonymous: boolean
        ├── parentId: string?       # 대댓글: 부모 댓글 ID
        ├── mentions: array<string>?# 멘션된 UID 목록 (최대 20)
        └── createdAt: timestamp
```

### chats/{chatId}

1:1 채팅방

```
chats/{chatId}
├── participants: array<string>     # 참여자 UID 2명
├── lastMessage: string             # 마지막 메시지 미리보기
├── lastMessageAt: timestamp        # 마지막 메시지 시각
├── unreadCount: map<string, number># UID → 안 읽은 수
│
└── messages/                       # 서브컬렉션: 메시지
    └── {messageId}/
        ├── content: string         # 메시지 내용 (0~2000자)
        ├── senderUid: string       # 발신자 UID
        ├── senderName: string
        ├── imageUrl: string?       # 이미지 URL
        ├── type: string?           # "system" (시스템 메시지)
        ├── deleted: boolean?       # 양쪽 삭제
        ├── deletedFor: array<string>?# 나만 삭제
        └── createdAt: timestamp
```

### reports/{reportId}

게시글/댓글 신고

```
reports/{reportId}
├── reporterUid: string             # 신고자 UID
├── postId: string                  # 신고 대상 글 ID
├── commentId: string?              # 댓글 신고 시 댓글 ID
├── reason: string                  # 신고 사유 (1~200자)
├── createdAt: timestamp
```

### app_config/

앱 설정 문서들

```
app_config/
├── popup/                          # 팝업 공지 설정
│   ├── active: boolean
│   ├── type: string                # "emergency" | "event" | "notice"
│   ├── title: string
│   ├── content: string
│   ├── startDate: timestamp
│   ├── endDate: timestamp
│   └── dismissible: boolean
│
└── version/                        # 앱 버전 관리
    ├── min: string                 # 최소 버전 (강제 업데이트)
    ├── latest: string              # 최신 버전 (선택 업데이트)
    ├── updateUrl: string           # 기본 업데이트 URL
    ├── updateUrlAndroid: string?
    └── updateUrlIOS: string?
```

### 기타 컬렉션

| 컬렉션 | 용도 |
|--------|------|
| `admin_logs/{logId}` | 관리자 작업 로그 (생성만 가능, 수정/삭제 불가) |
| `function_logs/{logId}` | Cloud Functions 에러 로그 |
| `crash_logs/{logId}` | 클라이언트 크래시 로그 |
| `app_feedbacks/{id}` | 앱 피드백 |
| `council_feedbacks/{id}` | 학생회 피드백 |

---

## Firestore Security Rules

### 헬퍼 함수

```javascript
isSignedIn()        // request.auth != null
isAdmin()           // users 문서의 role == 'admin'
isAdminOrManager()  // role in ['admin', 'manager']
changedKeys()       // 변경된 필드 목록
isInteractionUpdate() // 좋아요/싫어요/투표/댓글수/북마크만 변경
validCounterDelta(field) // 카운터 ±1 범위 검증
```

### 핵심 규칙

#### users
| 작업 | 조건 |
|------|------|
| read | 로그인 + (본인 또는 admin/manager) |
| create | 로그인 |
| update | 본인 (role/suspendedUntil/approved 변경 불가) 또는 admin/manager |
| delete | 본인 또는 admin |

**중요**: `update` 시 `.get('role', 'user')` 기본값을 사용해 필드 누락 시에도 규칙이 정상 작동

#### posts
| 작업 | 조건 |
|------|------|
| read | 누구나 (공개) |
| create | 로그인 + authorUid 일치 + 제목/본문 길이 검증 |
| update | 작성자 (자유 수정) 또는 인터랙션 필드만 (카운터 ±1 검증) |
| delete | 작성자 또는 admin/manager |

#### comments (posts 서브컬렉션)
| 작업 | 조건 |
|------|------|
| read | 누구나 |
| create | 로그인 + authorUid 일치 + 내용 길이 + mentions 배열 검증 |
| update | admin/manager만 (soft-delete 대비) |
| delete | 작성자 또는 admin/manager |

#### chats/messages
- 참여자만 읽기/쓰기 가능
- 메시지: senderUid 일치 또는 type=='system'
- 삭제: `deletedFor` (나만) / `deleted` + `content` (양쪽) 필드만 수정 가능

#### reports
- 로그인 사용자 누구나 생성 (reporterUid 일치 + reason 필수)
- admin/manager만 읽기/삭제

---

## Firebase Storage Rules

| 경로 | 읽기 | 쓰기 | 크기 제한 |
|------|------|------|-----------|
| `profile_photos/{file}` | 누구나 | 로그인 | 2 MB |
| `posts/{postId}/{file}` | 로그인 | 로그인 | 5 MB |
| `chats/{chatId}/{file}` | 로그인 | 로그인 | 5 MB |
| `feedbacks/{type}/{file}` | 로그인 | 로그인 | 5 MB |

모든 업로드는 `image/*` content-type만 허용

---

## Cloud Functions (functions/index.js)

Node.js 20, Firebase Functions v2 기반. Zod로 입력 검증

### HTTP 함수

#### `kakaoCustomAuth` (POST)
카카오 OAuth 토큰 → Firebase Custom Token 변환

```
요청: POST { token: "kakao_access_token" }
응답: { firebaseToken: "firebase_custom_token" }

흐름:
1. Zod 스키마로 입력 검증 (10~2000자 문자열)
2. Kakao API (/v2/user/me)로 토큰 유효성 확인
3. Firebase Auth에서 "kakao:{kakaoId}" UID로 사용자 조회/생성
4. 카카오 프로필 사진이 있으면 Firestore에 저장
5. Custom Token 발급 후 반환
```

#### `backfillCustomClaims` (POST)
기존 사용자에게 Custom Claims 일괄 적용 (1회성 마이그레이션)
`x-admin-secret` 헤더로 인증

### Firestore 트리거

#### `onCommentCreated` (posts/{postId}/comments/{commentId})
댓글 생성 시 알림 발송

```
알림 대상 (중복 제거):
1. 글 작성자 → "OO: 댓글내용" 푸시
2. 멘션된 사용자들 → "OO님이 회원님을 언급했습니다" 푸시
3. 대댓글 시 부모 댓글 작성자 → "답글 알림" 푸시

조건:
- 작성자가 approved 상태여야 발송
- 각 수신자의 notiComment/notiMention/notiReply 설정 확인
- 이미 알림 받은 사용자는 중복 발송 방지
```

#### `onPostCreated` (posts/{postId})
새 글 생성 시 FCM 토픽 알림

```
공지글 (isPinned) → "board_new_post" 토픽 (전체)
일반글 → "board_{category}" 토픽 (카테고리 구독자)
```

#### `onPostLikeUpdated` (posts/{postId})
좋아요 수가 10개를 처음 넘으면 인기글 알림

```
조건: beforeLikes < 10 && afterLikes >= 10
토픽: "board_popular"
```

#### `onUserCreated` (users/{userId})
새 사용자 생성 시 admin/manager에게 가입 알림 발송

#### `onUserUpdated` (users/{userId})
사용자 상태 변경 시 처리:

| 변경 | 동작 |
|------|------|
| role 변경 | Custom Claims 업데이트 + 권한 변경 알림 |
| approved 변경 | Custom Claims 업데이트 + 가입 승인 알림 |
| suspendedUntil 설정 | 정지 알림 |
| suspendedUntil 해제 | 정지 해제 알림 |

#### `onUserDeleted` (users/{userId})
사용자 삭제 시:
1. 거절/삭제 알림 발송
2. Firebase Auth 계정 삭제
3. 서브컬렉션 (subjects, notifications) 정리

#### `onChatMessageCreated` (chats/{chatId}/messages/{messageId})
채팅 메시지 생성 시 상대방에게 푸시 알림
이미지 메시지는 "[사진]"으로 표시

#### `onReportCreated` (reports/{reportId})
신고 레이트 리미팅: 5분 내 3건 초과 시 자동 삭제 + 로그

### 스케줄러

#### `checkSuspensionExpiry` (매시간)
정지 만료된 사용자의 `suspendedUntil` 필드 삭제
→ `onUserUpdated` 트리거 → 정지 해제 알림 자동 발송

#### `cleanupOldPosts` (매일 03:00 KST = 18:00 UTC)
4년 지난 비공지 게시글 자동 삭제:
1. 하위 댓글 삭제
2. Storage 이미지 삭제
3. 게시글 문서 삭제
4. 삭제 수 로그 기록

---

## FCM 토픽 구조

| 토픽 | 설명 |
|------|------|
| `board_new_post` | 전체 새 글 (공지글) |
| `board_free` | 자유 카테고리 |
| `board_question` | 질문 카테고리 |
| `board_info` | 정보공유 카테고리 |
| `board_lost` | 분실물 카테고리 |
| `board_council` | 학생회 카테고리 |
| `board_club` | 동아리 카테고리 |
| `board_popular` | 인기글 (좋아요 10+) |

**주의**: 한국어 카테고리명은 FCM 토픽으로 사용 불가 (영문 매핑 필요)
```dart
static const _categoryTopicKey = {
  '자유': 'free', '질문': 'question', '정보공유': 'info',
  '분실물': 'lost', '학생회': 'council', '동아리': 'club',
};
```

---

## Firestore 복합 인덱스

| 컬렉션 | 필드 | 용도 |
|--------|------|------|
| posts | category ↑, createdAt ↓ | 카테고리별 최신글 |
| posts | authorUid ↑, createdAt ↓ | 내 글 목록 |
| posts | bookmarkedBy (array), createdAt ↓ | 북마크 목록 |
| posts | isPinned ↑, createdAt ↓ | 고정글 + 최신글 |
| posts | category ↑, likeCount ↓, createdAt ↓ | 인기글 정렬 |
| chats | participants (array), lastMessageAt ↓ | 채팅방 목록 |
| admin_logs | action ↑, createdAt ↓ | 관리 로그 |
| reports | postId ↑, reporterUid ↑ | 중복 신고 체크 |
| reports | reporterUid ↑, createdAt ↓ | 신고 이력 |

---

## Firebase 프로젝트 설정

| 항목 | 값 |
|------|-----|
| Project ID | `hansol-high-school-46fc9` |
| Android 패키지 | (google-services.json 참조) |
| iOS 번들 ID | `com.monkshark.hansolHighSchool` |
| Functions Runtime | Node.js 20 |
| Emulator Ports | Firestore: 8080, Auth: 9099 |

### App Check

```dart
// Android
Release: PlayIntegrity
Debug: DebugProvider

// iOS (현재)
Debug: DebugProvider
// iOS (Apple 개발자 등록 후)
Release: AppAttest
```

---

## 에러 로깅

### function_logs 컬렉션
모든 Cloud Function 에러가 기록된다:

```javascript
await logError("functionName", error, { extra: "context" });
// → function_logs/{auto-id}
//   { function, error, code, stack, ...extra, createdAt }
```

### crash_logs 컬렉션
클라이언트 Flutter 에러가 기록된다 (로그인 상태일 때만):

```dart
// main.dart
FirebaseFirestore.instance.collection('crash_logs').add({
  'error': details.exceptionAsString(),
  'stack': details.stack?.toString(),
  'library': details.library,
  'uid': AuthService.currentUser?.uid,
  'createdAt': FieldValue.serverTimestamp(),
});
```
