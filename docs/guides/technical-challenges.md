# Technical Challenges & Solutions

> English: [technical-challenges_en.md](./technical-challenges_en.md)

개발 중 부딪힌 16건의 기술 과제와 해결 방법을 정리합니다. 각 사례는 *문제 → 해결 → 결과*의 흐름을 유지하고, 관련 파일 경로를 함께 남깁니다.

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
15. [권한 검사 Firestore 읽기 0회 — Custom Claims 마이그레이션](#15-권한-검사-firestore-읽기-0회--custom-claims-마이그레이션)
16. [PIPA TTL 데이터 라이프사이클 자동화](#16-pipa-ttl-데이터-라이프사이클-자동화)

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

**결과:** 4개 화면 합계 **4,575 → 1,919줄 (-58%)** — `post_detail` 545, `write_post` 700, `timetable_view` 588, `admin_screen` 86(+admin/ 5파일 1,123). 16개 위젯 모듈로 분리(`widgets/` 9 + `write_widgets/` 7), 563개 Flutter 테스트 모두 통과 (회귀 0)

**관련 파일:** `lib/screens/board/widgets/`, `lib/screens/board/write_widgets/`, `lib/screens/board/admin/`, `lib/screens/sub/timetable_widgets/`

---

## 14. Repository 패턴 + GetIt 점진적 마이그레이션

**문제:** `AuthService`/`GradeManager`가 static 메서드로 25개 이상의 호출 사이트에 흩어져 있어 한번에 DI로 전환하면 전 파일 수정 필요 + 회귀 위험

**해결:** Abstract `AuthRepository` / `GradeRepository` 인터페이스를 새로 정의하고 `FirebaseAuthRepository` / `LocalGradeRepository` 가 기존 static 메서드를 위임 호출. 신규 코드는 `GetIt.I<AuthRepository>()`로 가져가고 기존 호출 사이트는 그대로 둠. 테스트에서는 `setupServiceLocator()` / `resetServiceLocator()` + Mock 구현체로 주입 가능 → 점진적 마이그레이션과 백워드 호환을 동시에 확보

**관련 파일:** `test/auth_repository_test.dart`, `test/auth_service_test.dart`, `test/grade_manager_test.dart`

---

## 15. 권한 검사 Firestore 읽기 0회 — Custom Claims 마이그레이션

**문제:** 보안 규칙이 매 요청마다 `get(/databases/.../users/$uid).data.role`로 사용자 문서를 추가 조회 → 게시글 1건 읽을 때마다 추가 1회 읽기. 권한 모델을 4단계(`moderator`/`auditor`/`manager`/`admin`)로 확장하면서 트래픽이 비례 증가할 우려

**해결:**
1. 사용자의 `role`/`approved`를 Firebase Auth **custom claims**로 ID 토큰에 박음 → 보안 규칙은 `request.auth.token.role`로 직접 검사
2. `onUserUpdated` Cloud Function 트리거에서 `role` 필드 변경 감지 시 `setCustomUserClaims` 호출 → 권한 변경이 즉시 토큰에 반영
3. 클라이언트는 권한 변경 직후 `getIdTokenResult(true)` 강제 갱신
4. 기존 28명에 대해서는 `scripts/backfill-claims.js` (로컬 admin SDK)로 1회 백필. 단순한 루프지만 잘못 돌면 권한이 다 깨지므로 dry-run 후 적용

**결과:** 게시글/댓글 조회 시 권한 검사 추가 읽기 0회. Firestore 비용이 사용자 수가 아니라 트래픽에 비례하지 않게 됨. Rules 테스트 51건 추가 (4단계 매트릭스 검증)

**관련 파일:** `firestore.rules`, `functions/index.js` (`onUserUpdated`), `scripts/backfill-claims.js`, `tests/firestore-rules/test/rules.test.js`

---

## 16. PIPA TTL 데이터 라이프사이클 자동화

**문제:** PIPA(개인정보 보호법)는 보관 의무가 끝난 데이터를 자동 파기하라고 요구. 단순히 "삭제 버튼"을 만드는 건 일이 아닌데, 진짜 어려운 건 **사람 개입 없이 만료된 데이터가 사라지게** 하는 것. 매주 청소하는 시스템은 결국 안 청소됨

**해결:**
1. 새로 추가한 컬렉션(`appeals`, `data_requests`, `admin_logs`)에 `expiresAt: Timestamp` 필드를 강제
2. Firestore TTL 정책을 `expiresAt`에 바인딩 → 시각이 지나면 Firestore가 알아서 문서 삭제 (1회/일 정도, 비결정적이지만 PIPA 요건엔 충분)
3. 보관 기간은 정책 기반으로 차등: `appeals` 90일 / `data_requests` 30일 / `admin_logs` 1년
4. 데이터 익스포트는 Cloud Function `createDataExport`가 비동기 처리 — 사용자 데이터를 JSON으로 묶어 Storage 업로드, 다운로드 링크 이메일 발송. `purgeExpiredExports`가 일일 청소
5. 보안 규칙에서 `expiresAt` 필드의 존재/타입 검증을 강제 → TTL 누락 데이터 진입 차단

**결과:** 사람의 개입 없이 데이터가 정책대로 사라짐. 75개 파일 / 약 7,000줄 변경(인증 가드, 로그인 플로우, i18n 240키, 어드민 4페이지, Rules 테스트 등) — 법 조항 몇 줄을 만족시키려고 모든 레이어에 손이 감

**관련 파일:** `firestore.rules`, `firestore.indexes.json`, `functions/index.js` (`createDataExport`/`purgeExpiredExports`), `lib/screens/{appeal,data_request,community_rules}/`, `lib/services/verification_guard.dart`

---

## 참고
- [아키텍처 의사결정 일지](./architecture-decisions.md) — 각 과제에 연결된 설계 배경
- [테스트 전략](./testing.md) — 회귀 방지 테스트 체계
