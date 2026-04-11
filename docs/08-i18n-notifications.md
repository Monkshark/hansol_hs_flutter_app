# i18n 완성 + 알림 시스템 개선

> 국제화 완성, 인앱 언어 전환, 알림 딥링크, 버그 수정 작업을 정리함

---

## 1. i18n 완전 적용

### 개요
기존에 ARB 키가 적용되지 않은 모든 하드코딩 한국어 문자열을 `AppLocalizations` 키로 교체했다. 과목명·API 데이터 등 서버에서 오는 값은 제외

### 변경 범위

| 영역 | 파일 | 주요 변경 |
|------|------|----------|
| 게시판 | `post_detail_screen.dart`, `board_screen.dart`, `write_post_screen.dart` | `'익명'` → `l.post_anonymous`, `'관리자 승인 대기 중입니다'` → ARB 키 |
| 댓글 | `post_comment_item.dart` | `'익명'` fallback → ARB, `_formatTime` 로컬라이즈 |
| 내 활동 | `my_posts_screen.dart`, `bookmarked_posts_screen.dart` | `'로그인이 필요합니다'` → ARB |
| 알림 | `notification_screen.dart` | `'로그인이 필요합니다'` → ARB |
| 성적 입력 | `grade_input_screen.dart` | 정적 `_typeLabels`/`_mockMonths` → 로컬라이즈 메서드, 저장 값은 한국어 유지 (하위 호환) |
| 날짜 포맷 | `dday_screen.dart`, `home_screen.dart`, `meal_header.dart`, `today_banner.dart`, `main_calendar.dart`, `schedule_bottom_sheet.dart`, `event_attach_card.dart`, `write_event_form_section.dart`, `weekly_calendar.dart` | `DateFormat('M/d (E)', 'ko_KR')` → `DateFormat(l.common_dateMdE, Localizations.localeOf(context).toString())` |
| 시간표 | `timetable_select_screen.dart`, `teacher_timetable_select_screen.dart` | `'교시'` → `timetable_selectPeriod` ARB 키 |
| 알림 서비스 | `fcm_service.dart`, `daily_meal_notification.dart` | `'대화상대'` → ARB, 디바이스 로캘 감지 |
| 업데이트/팝업 | `update_checker.dart`, `popup_notice.dart` | `'필수 업데이트'`, `'공지'`, `'확인'` 등 → ARB |

### 성적 입력 화면 주의점
- Firestore 저장 값(`'3월'`, `'6월'` 등)은 한국어로 유지 → 기존 데이터 하위 호환
- UI 표시 레이블만 로컬라이즈 (`_localizedMonths(l)`, `_availableTypes(l)`)

---

## 2. 인앱 언어 전환

### 구현

| 파일 | 변경 |
|------|------|
| `main.dart` | `localeNotifier` (`ValueNotifier<Locale?>`) 추가, `MaterialApp`을 `ValueListenableBuilder`로 감싸서 `locale:` 파라미터 동적 전달 |
| `setting_data.dart` | `localeCode` getter/setter 추가 (SharedPreferences 저장) |
| `setting_screen.dart` | 테마 섹션 아래 언어 선택 UI 추가 (시스템 / 한국어 / English 3버튼) |

### 동작 방식
```
사용자가 버튼 탭
→ SettingData().localeCode = code ('' / 'ko' / 'en')
→ localeNotifier.value = code.isEmpty ? null : Locale(code)
→ ValueListenableBuilder rebuild
→ MaterialApp(locale: ...) 즉시 반영
```

- `null` (시스템): OS 설정 언어 따름
- `Locale('ko')`: 강제 한국어
- `Locale('en')`: 강제 영어

---

## 3. 알림 딥링크 라우팅

### 이전
- `type=comment/new_post` → `PostDetailScreen` (백그라운드에서만 동작)
- `type=chat` → `ChatRoomScreen`
- `type=account` → 무시 (앱만 열림)
- **포그라운드 알림 탭** → 아무 동작 없음 (로컬 알림 플러그인 미초기화)

### 이후

| type | 대상 | 이동 화면 |
|------|------|----------|
| `comment` / `new_post` | 게시글 작성자 / 구독자 | `PostDetailScreen` |
| `account` | 관리자 (가입 요청) | `AdminScreen` |
| `account` | 일반 유저 (승인/정지 등) | `NotificationScreen` |
| `chat` | 채팅 참여자 | `ChatRoomScreen` |

### 포그라운드 알림 탭 수정
`FcmService.initialize()`에서 `FlutterLocalNotificationsPlugin.initialize()` 호출 추가:
```dart
await _localNotifications.initialize(
  const InitializationSettings(android: androidSettings, iOS: iosSettings),
  onDidReceiveNotificationResponse: onNotificationTap,
);
```
→ 포그라운드에서 받은 FCM 알림 탭 시에도 딥링크 라우팅 동작

### 알림 목록 화면 탭
`notification_screen.dart`에서 account 타입 알림 탭 시:
- 관리자 → `AdminScreen` 이동
- 일반 유저 → 읽음 처리만 (이미 알림 화면에 있음)

---

## 4. 버그 수정

### 4-1. 댓글 중복 알림
**문제**: 내 익명글에 누군가 댓글 달면 "답글 알림" + "댓글 알림" 2개가 동시에 옴 (동일 내용)

**원인**: `post_detail_screen.dart`에서 대댓글 알림과 게시글 댓글 알림을 독립적으로 발송

**해결**: `replyNotifiedUid` 변수로 대댓글 알림을 보낸 UID를 추적, 게시글 작성자 알림 발송 시 해당 UID면 스킵:
```dart
if (postAuthorUid != myUid && postAuthorUid != replyNotifiedUid) {
  // 댓글 알림 발송
}
```

### 4-2. @멘션 띄어쓰기 이름 하이라이트
**문제**: `@12121 추희도`처럼 이름에 띄어쓰기가 있으면 `@12121`만 파란색으로 표시

**원인**: 멘션 정규식이 공백에서 끊김

**해결**: 정규식을 `@([\w가-힣]+(?: [\w가-힣]+)*)` 로 변경하여 공백 포함 이름 매칭. `post_detail_screen.dart`와 `post_comment_item.dart` 모두 적용

### 4-3. 관리자 화면 스크롤 시 섹션 오작동
**문제**: 삭제 로그를 펼친 상태에서 빠르게 스크롤하면 다른 `ExpansionTile`이 의도치 않게 열림

**원인**: `ExpansionTile`의 내부 `InkWell`이 스크롤 중에도 탭 이벤트를 받음

**해결**: `ExpansionTile` → 커스텀 `GestureDetector` + `AnimatedSize` 구현으로 교체. `NotificationListener<ScrollNotification>`으로 스크롤 시점 추적, 스크롤 직후 150ms 이내 탭은 무시

---

## 5. UX 개선

### 5-1. 알림 권한 요청 타이밍
**이전**: `main()`에서 앱 시작 즉시 `Permission.notification.request()`

**이후**: 온보딩 4페이지 완료 시 (`OnboardingScreen._finish()`) 요청
- 사용자가 앱의 기능을 먼저 확인한 후 권한을 결정할 수 있음
- 이미 온보딩을 완료한 기존 유저에게는 영향 없음

### 5-2. 관리자 화면 기본 접힘
**이전**: 승인 대기/신고/학생회 건의 섹션이 기본 펼침 (`initiallyExpanded: true`)

**이후**: 모든 섹션 기본 접힘 → 필요한 섹션만 선택적으로 펼치도록 변경
