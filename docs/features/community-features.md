# 커뮤니티 기능 (게시판 / 채팅 / 알림)

> English: [community-features_en.md](./community-features_en.md)

학생·교사·졸업생·학부모가 서로 소통하는 기능을 묶었습니다. 게시판, 1:1 채팅, 알림 시스템이 여기 포함됩니다.

## 게시판

### 카테고리 & 탐색

- **6개 카테고리** + **인기글** 탭: 자유 / 질문 / 정보공유 / 분실물 / 학생회 / 동아리
- **인기글 정렬**: `likeCount` 비정규화 카운터 + composite index `(likeCount desc, createdAt desc)` ([ADR-04](../architecture-decisions.md#adr-04-좋아요-카운터))
- **커서 기반 페이지네이션** (20개씩, 무한 스크롤, 당겨서 새로고침)
- **공지 시스템** (최대 3개, 상단 고정, 관리자 전용)

### 작성 / 본문

- **이미지 첨부**: 1080px 압축 + EXIF/GPS 제거, PageView swipe viewer + Hero animation + pinch-zoom
- **투표** 첨부 (최대 6선택지, 실시간 결과 바)
- **일정 공유** (학사일정 링크)
- **익명 번호제**: 익명1/익명2/익명(글쓴이), Firestore Transaction ([기술과제 #3](../technical-challenges.md#3-익명-게시판-번호-일관성-concurrent-write))

### 인터랙션

- **추천/비추천**: `Map<uid,bool>` + `likeCount` int counter, rules 단계 ±1 delta 검증 ([ADR-04](../architecture-decisions.md#adr-04-좋아요-카운터))
- **북마크** (내 활동 → 저장한 글에서 재조회)
- **댓글 + 대댓글** (들여쓰기), 글쓴이 댓글 구분 (파란 배경 + 뱃지)

### 검색

- **n-gram 검색**: 제목+본문 2-gram을 `searchTokens` 배열에 인덱싱, `array-contains-any` 쿼리 ([ADR-03](../architecture-decisions.md#adr-03-게시판-검색-클라이언트-n-gram-인덱싱))
- **350ms debounce**, 50개 fetch + client substring 필터로 false positive 줄임
- **검색 history**: 최근 10개 검색어 chip, 개별/전체 삭제

### UX

- Shimmer 스켈레톤 로딩
- **바텀시트 메뉴** (아이콘 + 텍스트, 삭제/신고 빨간색 강조)
- 신고, 사용자 차단, 글 자동 삭제 (TTL), Rate Limiting

### 내 활동

- 내가 쓴 글 / 내가 쓴 댓글 / 저장한 글 탭 분리
- `authorUid + createdAt` composite index 사용

**관련 파일**: `lib/screens/board/board_screen.dart`, `post_detail_screen.dart`, `write_post_screen.dart`, `my_posts_screen.dart`, `bookmarked_posts_screen.dart`, `search_history_service_test.dart`, `search_tokens_test.dart`

## 1:1 채팅

- **유저 검색**으로 새 채팅 시작 (이름/학번 검색, 관리자 기본 표시)
- **실시간 메시지** (Firestore onSnapshot, limit 30)
- **읽음 표시** + 읽지 않은 메시지 수 뱃지 ([기술과제 #6](../technical-challenges.md#6-채팅-읽음-확인-실시간-동기화-dual-stream))
- **메시지 삭제**: 나만 삭제 / 같이 삭제 (안 읽었고 1시간 이내)
- **채팅방 나가기**: 시스템 메시지 + 상대방 채팅 유지
- 스켈레톤 로딩 UI

**보안**: `chats/{chatId}`의 `participants` 배열 기반 rules 검증. 참여자만 read/write.

**관련 파일**: `lib/screens/chat/chat_list_screen.dart`, `chat_room_screen.dart`, `chat_utils.dart`

## 알림 시스템

### 설정 화면

**5개 카테고리** 개별 on/off:

| 카테고리 | 트리거 | 경로 |
|---|---|---|
| **댓글/답글** | 내 글에 댓글 / 내 댓글에 답글 | Cloud Functions → FCM |
| **채팅** | 새 메시지 | Cloud Functions → FCM |
| **새 글** | 관심 카테고리 새 글 | Cloud Functions → FCM |
| **계정** | 승인/정지/해제/역할변경 | Cloud Functions → FCM |
| **급식** | 조식/중식/석식 | 로컬 알림 (시간 설정) |

### 구현

- **인앱 알림**: 벨 아이콘 + 안 읽은 뱃지 (`users/{uid}/notifications/{id}`)
- **FCM 푸시**: 총 13종 (FCM 10 + 로컬 3)
- **서버 필터링**: `users/{uid}`의 `notiXxx` 필드를 Cloud Functions에서 발송 전 체크 ([기술과제 #7](../technical-challenges.md#7-cloud-functions-알림-설정-개별-제어-server-side-filtering))
- **정지 만료 자동 해제**: Cloud Functions 스케줄러 (매시간) ([기술과제 #8](../technical-challenges.md#8-정지-만료-자동-해제-scheduler-trigger))

**관련 파일**: `lib/notification/fcm_service.dart`, `lib/screens/sub/notification_setting_screen.dart`, `lib/screens/board/notification_screen.dart`, `functions/index.js`

## 건의사항

- **앱 건의사항 & 버그 제보** + **학생회 건의사항** 두 채널
- 텍스트(1000자) + 사진 첨부(최대 3장)
- 상태 관리: 대기중 → 확인됨 → 해결됨 → 삭제 (로그 기록)
- 관리자 Admin Web에서 상태 변경

**관련 파일**: `lib/screens/sub/feedback_screen.dart`, `feedback_list_screen.dart`

## Rate Limiting

| 대상 | 제한 |
|---|---|
| 글 작성 | 30초 쿨타임 |
| 댓글 작성 | 10초 쿨타임 |
| 신고 | 동일 `(postId, reporterUid)` 중복 방지 (인덱스) |
| 채팅 메시지 | (기본 클라이언트 debounce) |

Rate Limit은 클라이언트 선방어 + Firestore Rules에서 최소 검증.

## 관련 문서
- [공개 기능](./public-features.md)
- [개인 기능](./personal-features.md)
- [관리자 기능](./admin-features.md)
- [보안 모델](../security.md)
- [데이터 모델](../data-model.md) — `posts`, `comments`, `chats`, `reports` 스키마
