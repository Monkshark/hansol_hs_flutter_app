# 화면별 상세 가이드

---

## 인증 화면 (screens/auth/)

### LoginScreen (`login_screen.dart`)

**역할**: 소셜 로그인 화면. 4개 OAuth 프로바이더 지원

**로그인 흐름**:
```
1. 사용자가 로그인 버튼 탭
2. AuthService.signInWith{Provider}() 호출
3. FcmService.onUserLogin() → FCM 토큰 갱신
4. AuthService.hasProfile() 체크 (최대 3회 재시도)
5. 프로필 없음 → ProfileSetupScreen으로 이동
6. 프로필 있음 → pop (메인으로 복귀)
```

**프로바이더별 특이사항**:
- **Google**: `google_sign_in` SDK 사용. 가장 기본적인 플로우
- **Apple**: nonce 생성 + SHA256 해싱. iOS만 네이티브, 다른 플랫폼은 웹 팝업
- **Kakao**: Kakao SDK → Cloud Function (`kakaoCustomAuth`) → Custom Token 발급
- **GitHub**: Firebase Auth의 `GithubAuthProvider`를 통한 웹 기반 OAuth

**UI 특징**: SVG 브랜드 아이콘, 다크/라이트 모드 대응, 로딩 중 버튼 비활성화

---

### ProfileSetupScreen (`profile_setup_screen.dart`)

**역할**: 최초 가입 시 정보 입력 & 새 학기 업데이트

**`isUpdate` 파라미터**:
- `false` (기본): 최초 가입. 뒤로 가기 차단 (`canPop: false`). 개인정보 동의 필수
- `true`: 새 학기 업데이트. 신분 변경 불가 (잠금 표시)

**신분별 입력 필드**:
| 신분 | 필드 |
|------|------|
| 재학생 (`student`) | 이름, 학번 (5자리 검증) |
| 졸업생 (`graduate`) | 이름, 졸업연도 |
| 교사 (`teacher`) | 이름, 담당과목 (선택) |
| 학부모 (`parent`) | 이름만 |

**학번 검증 (`_validateStudentId`)**:
```
5자리 숫자: GCCNN
├── G: 학년 (1~3)
├── CC: 반 (01~12)
└── NN: 번호 (01~30)

예: "20301" → 2학년 3반 1번
```

**저장 후 동작**:
1. Firestore `users/{uid}`에 프로필 저장 (merge)
2. 최초 가입이면 관리자에게 가입 알림 전송
3. [`AuthService`](data/auth_service.md)`.clearProfileCache()` 호출
4. `Navigator.pop(true)` 반환

---

### ProfileEditScreen (`profile_edit_screen.dart`)

**역할**: 프로필 사진 변경 및 계정 삭제

**프로필 사진 업로드**:
```
1. ImagePicker로 갤러리/카메라 선택
2. flutter_image_compress로 70% 품질 압축
3. Firebase Storage `profile_photos/{uid}.jpg` 업로드
4. Firestore user doc에 profilePhotoUrl 업데이트
```

**계정 삭제**:
```
1. 확인 모달: 이메일 입력 (Kakao는 이름 입력)
2. Firebase Auth 재인증 시도
3. Firestore user doc 삭제
4. Firebase Auth 계정 삭제
5. 로그아웃 + 앱 리프레시
```

---

## 메인 탭 화면 (screens/main/)

### HomeScreen (`home_screen.dart`)

**역할**: 홈 대시보드. 오늘의 정보 한눈에 보기

**표시 정보**:
- 현재 수업 카드 (`CurrentSubjectCard`)
- D-day 카운트다운
- 오늘 중식 미리보기
- 최근 게시글 (고정글 + 최신 5개)
- 읽지 않은 알림 수
- 외부 링크 (NEIS+, 리로스쿨, 학교 홈페이지)

**네비게이션 진입점**:
```
HomeScreen
  ├── 왼쪽 상단: 관리자 방패 아이콘 → AdminScreen
  ├── 알림 벨 → NotificationScreen
  ├── 설정 톱니 → SettingScreen
  ├── 게시판 카드 → BoardScreen
  ├── 채팅 카드 → ChatListScreen
  ├── 성적 카드 → GradeScreen
  └── 외부 링크 → url_launcher
```

**앱 라이프사이클**: `WidgetsBindingObserver`로 앱이 포그라운드로 돌아올 때 D-day 등 새로고침

---

### MealScreen (`meal_screen.dart`)

**역할**: 주간 급식 조회

**데이터 흐름**:
```
1. WeeklyCalendar에서 날짜 선택
2. MealDataApi.getMeal(date, mealType) 호출 (조식/중식/석식)
3. MealCard 위젯으로 표시
```

**캐싱**: [MealDataApi](api/meal_data_api.md) 내부에서 응답 캐싱. 주간 데이터 프리페치

---

### NoticeScreen (`notice_screen.dart`)

**역할**: 캘린더 뷰 + 학사일정 + 개인 일정

**데이터 소스 2개**:
1. [`NoticeDataApi`](api/notice_data_api.md) → NEIS 학사일정 (서버)
2. [`LocalDataBase`](data/local_database.md) → 개인 일정 (SQLite)

**캘린더**: `table_calendar` 위젯 사용. 날짜 마커로 일정 표시

**일정 추가**: ScheduleBottomSheet에서 시작/종료 시간, 내용, 색상 선택

**스와이프 삭제**: `Dismissible` 위젯으로 개인 일정 슬라이드 삭제

---

## 게시판 화면 (screens/board/)

### BoardScreen (`board_screen.dart`)

**역할**: 게시판 메인. 카테고리 탭 + 글 목록 + 검색

**카테고리** (6개):
```dart
['자유', '질문', '정보공유', '분실물', '학생회', '동아리']
```

**카테고리 전환**: `PageView.builder`로 좌우 스와이프 전환. 상단 칩으로도 선택 가능

**글 목록 쿼리**:
```dart
FirebaseFirestore.instance
  .collection('posts')
  .where('category', isEqualTo: category)
  .orderBy('createdAt', descending: true)
  .limit(20)
```

**고정글**: `pinnedAt` 타임스탬프가 있는 글을 상단에 정렬

**인기글**: `likeCount` 기준 정렬 (별도 쿼리)

**검색 (n-gram)**:
```dart
.where('searchTokens', arrayContainsAny: tokens)
```
+ 클라이언트 사이드 substring 추가 필터링. 350ms 디바운스

**페이지네이션**: `lastDoc` 기반 커서 페이지네이션

---

### PostDetailScreen (`post_detail_screen.dart`)

**역할**: 글 상세 보기, 댓글, 투표, 북마크

**실시간 스트림** (2개):
1. 글 본문: `posts/{postId}` 문서 스냅샷
2. 댓글: `posts/{postId}/comments` 서브컬렉션 스트림

**인터랙션**:

| 기능 | Firestore 필드 | 설명 |
|------|----------------|------|
| 좋아요 | `likes` (Map), `likeCount` | UID → true/null |
| 싫어요 | `dislikes` (Map), `dislikeCount` | UID → true/null |
| 북마크 | `bookmarkedBy` (Array) | arrayUnion/arrayRemove |
| 투표 | `pollVoters` (Map) | UID → 선택 인덱스 |
| 댓글 수 | `commentCount` | ±1 increment |

**댓글 작성**:
```
1. FocusScope.unfocus() (키보드 닫기)
2. Firestore comments 서브컬렉션에 추가
3. commentCount +1 업데이트
4. StreamBuilder가 자동으로 새 댓글 표시 (새로고침 불필요)
```

**익명 시스템**:
- 글 단위로 `anonymousMapping` (Map<UID, int>) 유지
- "익명1", "익명2" 등 순서대로 할당
- 같은 글 내에서 같은 사용자는 항상 같은 번호

**스와이프 제스처**: 오른쪽 스와이프로 뒤로 가기 (pop)

---

### WritePostScreen (`write_post_screen.dart`)

**역할**: 글 작성 및 수정

**기능**:
- 카테고리 선택
- 제목/본문 입력 (제목 200자, 본문 5000자 제한)
- 이미지 첨부 (최대 여러 장, 80% 압축, 1080px 리사이즈)
- 투표 옵션 추가 (동적 추가/삭제)
- 일정 첨부 (날짜/시간 선택)
- 익명 토글
- 고정 토글 (manager 이상, 최대 3개)

**임시저장**: SharedPreferences에 제목/본문 자동 저장. 종료 시 확인 다이얼로그 (저장/삭제/취소)

**글 저장 프로세스**:
```
1. 이미지 업로드 → Firebase Storage (posts/{postId}/*.jpg)
2. SearchTokens 생성 (제목 + 본문 2-gram)
3. Firestore posts 컬렉션에 문서 생성/업데이트
4. 레이트 리미팅: 30초 내 재작성 방지
```

---

### MyPostsScreen (`my_posts_screen.dart`)

**역할**: 내 활동 (내 글/내 댓글/북마크) 3탭

| 탭 | 쿼리 |
|----|------|
| 내 글 | `posts WHERE authorUid == uid` |
| 내 댓글 | `collectionGroup('comments') WHERE authorUid == uid` |
| 북마크 | `posts WHERE bookmarkedBy array-contains uid` |

---

### NotificationScreen (`notification_screen.dart`)

**역할**: 실시간 알림 목록

**알림 타입**:
| 타입 | 아이콘 | 내용 |
|------|--------|------|
| `comment` | 채팅 버블 | "OO님이 댓글을 남겼습니다" |
| `reply` | 리플라이 | "OO님이 대댓글을 남겼습니다" |
| `account` | 사람 | "OO님이 가입을 요청했습니다" |

**데이터**: `users/{uid}/notifications` 서브컬렉션 스트림

---

## 채팅 화면 (screens/chat/)

### ChatListScreen (`chat_list_screen.dart`)

**역할**: 1:1 채팅 목록

**쿼리**:
```dart
chats.where('participants', arrayContains: uid)
     .orderBy('lastMessageAt', descending: true)
```

**새 채팅**: 사용자 검색 모달 → 기존 채팅방 있으면 이동, 없으면 새로 생성

### ChatRoomScreen (`chat_room_screen.dart`)

**역할**: 1:1 채팅 메시지

**기능**:
- 실시간 메시지 스트림 (limit 30)
- 이미지 전송 (압축 + Storage 업로드)
- 메시지 삭제: 나만 삭제 (`deletedFor` 배열) / 같이 삭제 (1시간 이내 + 안 읽음)
- 읽음 표시: per-message 카운터 방식 — 상대방 `unreadCount` 로 `myUnreadRemaining` 초기화 후 최신 메시지부터 차감, 카운터 소진 후 메시지에 "읽음" 표시
- 채팅방 나가기: 시스템 메시지 추가 + `participants` 에서 제거

---

## 설정/부가 화면 (screens/sub/)

### SettingScreen (`setting_screen.dart`)

**역할**: 앱 설정 (테마, 학년/반, 알림, 캐시 등)

**주요 설정**:
- 테마 모드 (라이트/다크/시스템)
- 학년/반 선택 → [SettingData](data/setting_data.md) 반영
- 급식 알림 시간 설정
- 게시판 알림 on/off
- 캐시 크기 표시 및 삭제
- 개인정보 처리방침 (15개 조항)

---

### GradeScreen (`grade_screen.dart`) — Riverpod

**역할**: 성적 관리 (수시/정시 탭)

**Riverpod 프로바이더**:
- `examsProvider` — 시험 목록
- `goalsProvider` — 수시 목표
- `jeongsiGoalsProvider` — 정시 목표
- `examsByTypeProvider(tab)` — 탭별 필터

**UI**: PageView 2탭 (수시/정시), GradeChart 시각화, 시험 카드 목록

---

### TimetableViewScreen (`timetable_view_screen.dart`)

**역할**: 주간 시간표 그리드

**UI**: 5열(월~금) × 7행(1~7교시) 그리드. 셀 탭 시 색상 변경

**데이터**: [`TimetableDataApi`](api/timetable_data_api.md)에서 fetch, [`SubjectDataManager`](data/subject_data_manager.md)에서 선택과목 관리

**과목 충돌**: 선택과목이 같은 시간에 겹치면 `ConflictDialog`로 해결

---

### DDayScreen (`dday_screen.dart`)

**역할**: D-day 관리

**기능**: 추가/삭제/고정(pin), 캘린더 일정에서 D-day 추천, 드래그 순서 변경

---

### FeedbackScreen (`feedback_screen.dart`)

**역할**: 사용자 피드백/버그 신고

**제한**: 내용 1000자, 이미지 최대 3장 (640px 압축)

**저장**: `app_feedbacks` 또는 `council_feedbacks` 컬렉션

---

### OnboardingScreen (`onboarding_screen.dart`)

**역할**: 최초 실행 시 4페이지 튜토리얼

`onboarding_done` SharedPreferences 플래그로 1회만 표시

---

### NotificationSettingScreen (`notification_setting_screen.dart`)

**역할**: 세분화된 알림 설정

**설정 그룹**:
1. **급식 알림** — 조식/중식/석식 on/off + 시간 설정
2. **게시판 알림** — 전체 on/off + 카테고리별 구독
3. **인기글 알림** — on/off

FCM 토픽 구독/해제와 연동
