# 관리자 시스템 가이드

---

## 권한 체계

### 역할 (role)

| 역할 | 권한 |
|------|------|
| `admin` | 모든 관리 기능 + 역할 변경 + 계정 삭제 |
| `manager` | 대부분의 관리 기능 (글/댓글 삭제, 승인, 정지 등) |
| `user` | 일반 사용자 (게시판 이용, 댓글 작성 등) |

### 승인 (approved)

신규 가입자는 `approved: false` 상태.
admin 또는 manager가 승인해야 게시판 등 주요 기능 이용 가능.

```
가입 → approved: false → 관리자 승인 → approved: true → 모든 기능 이용
```

### 정지 (suspendedUntil)

관리자가 특정 기간 동안 사용자를 정지할 수 있다.

```
정지 설정 → suspendedUntil: timestamp → 기능 제한
매시간 스케줄러 → 만료 확인 → suspendedUntil: null → 자동 해제
```

### Custom Claims 동기화

Firestore의 role/approved 변경 시 Cloud Function이 Firebase Auth Custom Claims에 자동 동기화:

```javascript
// onUserUpdated Cloud Function
await getAuth().setCustomUserClaims(userId, {
  role: after.role || "user",
  approved: after.approved === true,
});
```

클라이언트에서 ID 토큰 강제 갱신:
```dart
static Future<void> refreshCustomClaims() async {
  await FirebaseAuth.instance.currentUser?.getIdToken(true);
}
```

---

## 인앱 관리자 화면 (screens/board/admin/)

### AdminScreen (`admin_screen.dart`)

TabBar 기반 관리 대시보드.

**탭 구성**:
1. 가입 대기 (`UsersTab` - pending)
2. 정지 유저 (`UsersTab` - suspended)
3. 승인 유저 (`UsersTab` - approved)
4. 신고 관리 (`ReportsTab`)
5. 삭제 로그 (`DeleteLogsTab`)
6. 팝업 관리 (`PopupNoticeManager`)
7. 피드백 (`FeedbackListScreen`)

### 탭 간 상태 동기화

`GlobalKey` 패턴으로 한 탭에서의 액션이 다른 탭에도 반영된다:

```dart
// admin_screen.dart
final _pendingKey = GlobalKey<UsersTabState>();
final _suspendedKey = GlobalKey<UsersTabState>();
final _approvedKey = GlobalKey<UsersTabState>();

void _refreshAllTabs() {
  _pendingKey.currentState?.refresh();
  _suspendedKey.currentState?.refresh();
  _approvedKey.currentState?.refresh();
}
```

### UsersTab (`admin/users_tab.dart`)

사용자 관리 탭. 필터 모드에 따라 다른 쿼리:

| 모드 | Firestore 쿼리 |
|------|----------------|
| pending | `approved == false` (정지 아닌 유저) |
| suspended | `suspendedUntil != null` |
| approved | `approved == true` |

**관리 액션**:

| 액션 | 설명 | 대상 역할 |
|------|------|-----------|
| 승인 | approved → true | admin, manager |
| 거절 | 유저 문서 삭제 | admin, manager |
| 정지 | suspendedUntil 설정 (1일~영구) | admin, manager |
| 정지 해제 | suspendedUntil → null | admin, manager |
| 삭제 | 유저 문서 삭제 + Auth 삭제 | admin |
| 역할 변경 | role 변경 | admin만 |

모든 액션은 `_refreshAll()` 호출 → 3개 탭 모두 새로고침.

### ReportsTab (`admin/reports_tab.dart`)

게시글/댓글 신고 관리.

```
reports 컬렉션 조회
  ├── 글 보기 (PostDetailScreen으로 이동)
  ├── 글 삭제 (posts 문서 삭제)
  ├── 신고 무시 (reports 문서 삭제)
  └── 사용자 정지 (suspendedUntil 설정)
```

### DeleteLogsTab (`admin/delete_logs_tab.dart`)

관리자 작업 로그 조회 (`admin_logs` 컬렉션).

```
admin_logs/{id}
├── action: string     # "delete_post" | "delete_comment" | "approve" | ...
├── adminUid: string
├── adminName: string
├── targetId: string
├── detail: string
└── createdAt: timestamp
```

### PopupNoticeManager (`admin/popup_notice_manager.dart`)

인앱 팝업 공지 관리 (`app_config/popup` 문서).

설정 가능 항목:
- 활성화/비활성화
- 타입: emergency (긴급) / event (행사) / notice (공지)
- 제목, 내용
- 표시 기간 (시작~종료)
- 닫기 가능 여부 (dismissible)

---

## 관리자 웹 대시보드 (admin-web/)

Next.js 16 + React 18 + Tailwind CSS 기반 웹 관리 도구.

### 페이지 구성

| 페이지 | 경로 | 기능 |
|--------|------|------|
| 대시보드 | `/dashboard` | 통계 개요 (유저 수, 글 수, 신고 수) |
| 사용자 관리 | `/users` | 승인/거절/정지/역할변경 |
| 사용자 상세 | `/users/[id]` | 개별 유저 프로필 및 활동 |
| 게시글 관리 | `/posts` | 글 목록, 검색, 삭제 |
| 게시글 상세 | `/posts/[id]` | 글 내용 및 댓글 관리 |
| 댓글 관리 | `/comments` | 전체 댓글 조회/삭제 |
| 신고 관리 | `/reports` | 신고 처리 |
| 크래시 로그 | `/crashes` | 클라이언트 에러 로그 |
| Functions 로그 | `/function-logs` | Cloud Function 에러 로그 |
| 피드백 | `/feedbacks` | 사용자 피드백 |
| 설정 | `/settings` | 앱 설정 (버전, 팝업 등) |

### 공통 컴포넌트

- `Sidebar` — 좌측 네비게이션
- `Badge` — 상태 표시 (승인/미승인/정지 등)
- `StatsCard` — 통계 카드 (Recharts 차트)

### 환경 설정

`admin-web/.env.local` (gitignore 대상):
```env
NEXT_PUBLIC_FIREBASE_API_KEY=...
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=...
NEXT_PUBLIC_FIREBASE_PROJECT_ID=...
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=...
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=...
NEXT_PUBLIC_FIREBASE_APP_ID=...
```

---

## 신고 시스템 흐름

```
1. 사용자가 글/댓글 신고
   └── reports 컬렉션에 문서 생성
       ├── reporterUid, postId, commentId?, reason, createdAt

2. Cloud Function (onReportCreated) 레이트 리미팅
   └── 5분 내 3건 초과 시 자동 삭제 + 로그

3. 관리자 확인 (인앱 또는 웹)
   ├── 글 삭제 → posts 문서 삭제
   ├── 사용자 정지 → suspendedUntil 설정
   ├── 무시 → reports 문서 삭제
   └── admin_logs에 작업 기록
```

---

## 알림 시스템 (관리자 관련)

### 가입 요청 알림

```
사용자 가입 → ProfileSetupScreen._notifyAdminsNewSignup()
  └── admin/manager의 notifications 서브컬렉션에 알림 추가

+ Cloud Function (onUserCreated)
  └── admin/manager에게 FCM 푸시 발송
```

### 상태 변경 알림

| 이벤트 | 알림 내용 |
|--------|-----------|
| 가입 승인 | "가입이 승인되었습니다" |
| 가입 거절 | "가입이 거절되었습니다" |
| 정지 | "관리자에 의해 계정이 정지되었습니다" |
| 정지 해제 | "계정 정지가 해제되었습니다" |
| 역할 변경 | "{새 역할}(으)로 변경되었습니다" |
| 계정 삭제 | "관리자에 의해 계정이 삭제되었습니다" |

모든 알림은 `onUserUpdated` / `onUserDeleted` Cloud Function에서 자동 처리.
사용자의 `notiAccount` 설정이 false면 발송하지 않음.
