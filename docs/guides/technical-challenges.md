# Technical Challenges & Solutions

> English: [technical-challenges_en.md](./technical-challenges_en.md)

개발 중 부딪힌 14건의 기술 과제와 해결 방법을 정리합니다. 각 사례는 *문제 → 해결 → 결과*의 흐름을 유지하고, 관련 파일 경로를 함께 남깁니다.

## 목차

1. [Firebase Auth 토큰 동기화 문제](#1-firebase-auth-토큰-동기화-문제-permission-denied)
2. [급식 API 동시 요청 경합](#2-급식-api-동시-요청-경합-race-condition)
3. [익명 게시판 번호 일관성](#3-익명-게시판-번호-일관성-concurrent-write)
4. [선택과목 시간표 충돌](#4-선택과목-시간표-충돌-slot-conflict)
5. [Firestore 보안 규칙과 기능 충돌](#5-firestore-보안-규칙과-기능-충돌-field-level-validation)
6. [채팅 읽음 확인 실시간 동기화](#6-채팅-읽음-확인-실시간-동기화-dual-stream)
7. [Cloud Functions 알림 설정 개별 제어](#7-cloud-functions-알림-설정-개별-제어-server-side-filtering)
8. [정지 만료 자동 해제](#8-정지-만료-자동-해제-scheduler-trigger)
9. [관리자 화면 Firestore 읽기 과다](#9-관리자-화면-firestore-읽기-과다-stream--future-전환)
10. [계정 삭제 순서 문제](#10-계정-삭제-순서-문제-auth--firestore-권한-소실)
11. [Riverpod AsyncNotifier 경합 상태](#11-riverpod-asyncnotifier-경합-상태-invalidateself-race-condition)
12. [위젯 테스트의 비결정적 Timer Leak](#12-위젯-테스트의-비결정적-timer-leak)
13. [StatefulWidget 1,400+ 라인 리팩토링](#13-statefulwidget-1400-라인--stateless-composition-refactoring)
14. [Repository 패턴 + GetIt 점진적 마이그레이션](#14-repository-패턴--getit-점진적-마이그레이션)

---

## 1. Firebase Auth 토큰 동기화 문제 (Permission Denied)

**문제:** 소셜 로그인 직후 Firestore 문서 조회 시 PERMISSION_DENIED 발생 — Auth 토큰이 Firestore SDK에 전파되기 전에 요청이 나감

**해결:** `getIdToken(true)`로 토큰 강제 갱신 + 최대 3회 재시도 로직으로 첫 설치/재로그인 시에도 안정적으로 프로필 확인

**관련 파일:** `lib/screens/auth/login_screen.dart`, `lib/screens/auth/profile_setup_screen.dart`

---

## 2. 급식 API 동시 요청 경합 (Race Condition)

**문제:** 여러 화면에서 동시에 같은 월의 급식 데이터를 요청하면 중복 API 호출 발생

**해결:** `Completer` 패턴으로 동일 월 프리페치를 단일 Future로 병합, 진행 중인 요청이 있으면 기존 Future를 공유

**결과:** API 호출 **30회 → 1회**

**관련 파일:** `lib/api/meal_data_api.dart`, `test/meal_api_test.dart`

---

## 3. 익명 게시판 번호 일관성 (Concurrent Write)

**문제:** 클라이언트에서 익명 번호를 부여하면 동시 댓글 시 같은 번호가 중복 할당될 수 있음

**해결:** Firestore Transaction으로 게시글 문서의 `anonymousMapping` / `anonymousCount`를 원자적으로 읽기/쓰기하여 번호 중복 방지. 작성자 본인은 `익명(글쓴이)` 고정 라벨

**관련 파일:** `lib/screens/board/post_detail_screen.dart`, `firestore.rules` (`isInteractionUpdate`가 `anonymousMapping` 포함)

---

## 4. 선택과목 시간표 충돌 (Slot Conflict)

**문제:** 2-3학년 선택과목 조합 시 같은 교시에 다른 반의 수업이 겹칠 수 있음

**해결:** 시간표 빌드 시 슬롯별 충돌 자동 감지 → 사용자에게 선택 다이얼로그 표시, 선택 결과를 로컬에 저장하여 재충돌 방지

**관련 파일:** `lib/screens/sub/timetable_view_screen.dart`, `lib/screens/sub/timetable_select_screen.dart`

---

## 5. Firestore 보안 규칙과 기능 충돌 (Field-level Validation)

**문제:** 게시글 update를 `작성자만` 허용하면 다른 유저의 투표/추천이 차단됨

**해결:** `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` 로 필드 단위 검증 — 인터랙션 필드만 변경 시 모든 인증 유저 허용. `validCounterDelta(field)`로 `likeCount` 등의 ±1 delta를 강제

**관련 파일:** `firestore.rules` (`isInteractionUpdate`, `validCounterDelta`), `tests/firestore-rules/`

---

## 6. 채팅 읽음 확인 실시간 동기화 (Dual Stream)

**문제:** 메시지 스트림과 별도로 읽음 상태를 추적하면 추가 Firestore 읽기 발생

**해결:** 채팅방 문서의 `unreadCount` 맵을 별도 `StreamBuilder`로 감시하여 단일 문서 스트림으로 읽음 상태 실시간 반영

**관련 파일:** `lib/screens/chat/chat_room_screen.dart`, `lib/screens/chat/chat_list_screen.dart`

---

## 7. Cloud Functions 알림 설정 개별 제어 (Server-side Filtering)

**문제:** FCM 푸시는 서버에서 발송하므로 클라이언트에서 카테고리별 on/off 불가

**해결:** Firestore `users/{uid}`에 `notiComment`, `notiReply`, `notiChat` 등 필드 저장, Cloud Functions에서 발송 전 해당 필드 체크하여 `false`면 발송 스킵

**관련 파일:** `functions/index.js`, `lib/screens/sub/notification_setting_screen.dart`

---

## 8. 정지 만료 자동 해제 (Scheduler Trigger)

**문제:** 계정 정지 만료 시간이 지나도 Firestore 필드가 자동으로 삭제되지 않아 `onUserUpdated` 트리거 불발

**해결:** Cloud Functions Scheduler로 매시간 `suspendedUntil <= now`인 유저를 조회하여 필드 삭제 → `onUserUpdated` 트리거 → 정지 해제 푸시 발송

**관련 파일:** `functions/index.js` (`checkSuspensionExpiry`)

---

## 9. 관리자 화면 Firestore 읽기 과다 (Stream → Future 전환)

**문제:** 관리자 화면이 `StreamBuilder`로 유저/신고/로그를 실시간 감시하여, 화면 열기만 해도 130+ 읽기 발생. 데이터 변경 시마다 전체 재조회

**해결:** `StreamBuilder` → `FutureBuilder`로 전환하여 열 때 1회만 조회 + 액션(승인/삭제 등) 후 `_refresh()`로 수동 갱신. `ExpansionTile`을 펼칠 때만 child를 렌더링하여 접힌 탭은 읽기 0

**결과:** **130 → 20~30 읽기로 감소**

**관련 파일:** `lib/screens/board/admin_screen.dart`, `lib/screens/board/admin/users_tab.dart`

---

## 10. 계정 삭제 순서 문제 (Auth → Firestore 권한 소실)

**문제:** `user.delete()` 호출 시 Firebase Auth가 즉시 로그아웃되어, 이후 Firestore 문서 삭제가 PERMISSION_DENIED로 실패

**해결:** Firestore 문서를 먼저 삭제(인증 상태 유지 중)한 후 Auth 계정 삭제. `uid`를 미리 변수에 저장하여 삭제 순서 역전에 의한 참조 소실 방지

**관련 파일:** `lib/screens/sub/setting_screen.dart`, `lib/screens/auth/profile_edit_screen.dart`

---

## 11. Riverpod AsyncNotifier 경합 상태 (invalidateSelf Race Condition)

**문제:** `ExamsNotifier`의 `add()` / `delete()` 같은 mutator에서 `ref.invalidateSelf()`로 재조회를 트리거했더니, Provider 단위 테스트가 간헐적으로 실패. invalidate가 비동기로 처리되어 다음 `read()`가 *이전* state를 반환하는 race condition

**해결:** mutator 내부에서 `final current = await future;` 로 현재 state를 먼저 확보 → 저장소 갱신 → `state = AsyncData([...current, exam])` 로 직접 state 교체. invalidateSelf를 제거하여 race condition 원천 차단. 동일 패턴을 `GoalsNotifier` / `JeongsiGoalsNotifier`에도 적용

**관련 파일:** `lib/providers/grade_provider.dart`, `test/grade_provider_test.dart`

---

## 12. 위젯 테스트의 비결정적 Timer Leak

**문제:** `_LoadingExamsNotifier` mock에서 `await Future.delayed(Duration(seconds: 30))`로 영구 로딩을 시뮬레이션했더니 `flutter test`가 "A Timer is still pending even after the widget tree was disposed" 로 실패

**해결:** `Completer<List<Exam>>` 패턴으로 교체 — Future를 외부 신호로 완료시킬 수 있도록 하여 테스트 종료 시점에 명시적으로 `complete()` 호출. Provider 테스트에서도 `addTearDown(container.dispose)`로 ProviderContainer 누수 방지

**관련 파일:** `test/grade_screen_widget_test.dart`, `test/helpers/`

---

## 13. StatefulWidget 1,400+ 라인 → Stateless Composition (Refactoring)

**문제:** `post_detail_screen.dart`(1442줄), `admin_screen.dart`(1071줄), `write_post_screen.dart`(1119줄), `timetable_view_screen.dart`(943줄) 4개 화면이 모든 sub-widget을 private 클래스 / `_buildXxx` 메서드로 한 파일에 가지고 있어 가독성/재사용성/테스트성이 모두 저하. 단순 string match로 재사용 위치를 찾기도 어려움

**해결:** 두 가지 패턴으로 분리
1. **Private class → Public StatelessWidget 추출** — `post_detail_screen` 의 `_PollCard` / `_VoteButton` / `_CommentItem` / `_EventAttachCard`, `admin_screen` 의 5개 탭 클래스, `timetable_view` 의 다이얼로그/Painter 등을 별도 파일로 이동 + `_` prefix 제거
2. **State 의존 builder method → Callback parameter 위젯** — `write_post_screen` 의 `_buildEventForm` / `_buildPollForm` / `_buildImageSection` 은 state를 직접 참조하므로, state 값과 setState wrapper를 명시적 callback (`onPickDate`, `onAddOption`, `onReorder`...)으로 받는 StatelessWidget으로 변환

**결과:** 4개 화면 합계 **4,575 → 1,919줄 (-58%)** — `post_detail` 545, `write_post` 700, `timetable_view` 588, `admin_screen` 86(+admin/ 5파일 1,123). 16개 위젯 모듈로 분리(`widgets/` 9 + `write_widgets/` 7), 524개 Flutter 테스트 모두 통과 (회귀 0)

**관련 파일:** `lib/screens/board/widgets/`, `lib/screens/board/write_widgets/`, `lib/screens/board/admin/`, `lib/screens/sub/timetable_widgets/`

---

## 14. Repository 패턴 + GetIt 점진적 마이그레이션

**문제:** `AuthService`/`GradeManager`가 static 메서드로 25개 이상의 호출 사이트에 흩어져 있어 한번에 DI로 전환하면 전 파일 수정 필요 + 회귀 위험

**해결:** Abstract `AuthRepository` / `GradeRepository` 인터페이스를 새로 정의하고 `FirebaseAuthRepository` / `LocalGradeRepository` 가 기존 static 메서드를 위임 호출. 신규 코드는 `GetIt.I<AuthRepository>()`로 가져가고 기존 호출 사이트는 그대로 둠. 테스트에서는 `setupServiceLocator()` / `resetServiceLocator()` + Mock 구현체로 주입 가능 → 점진적 마이그레이션과 백워드 호환을 동시에 확보

**관련 파일:** `test/auth_repository_test.dart`, `test/auth_service_test.dart`, `test/grade_manager_test.dart`

---

## 참고
- [아키텍처 의사결정 일지](./architecture-decisions.md) — 각 과제에 연결된 설계 배경
- [테스트 전략](./testing.md) — 회귀 방지 테스트 체계
