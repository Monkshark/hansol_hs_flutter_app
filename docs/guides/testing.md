# 테스트 전략

> English: [testing_en.md](./testing_en.md)

4계층 테스트 체계 (Unit + Provider + Widget + Golden + Firestore Rules)로 총 **597개** 테스트를 유지합니다.

## 한눈에 보기

| 계층 | 개수 | 특징 |
|---|---|---|
| `test()` 단위 | 440 | 모델/유틸/파서/Provider/Repository/Golden 포함 — 외부 의존 0 |
| `testWidgets()` 위젯 | 123 | `ProviderScope.overrides` + Mock Notifier 기반 UI 검증 (a11y 포함) |
| Integration | 4 | `integration_test/` — 앱 네비게이션 E2E |
| Firestore Rules | 34 | `@firebase/rules-unit-testing` + 에뮬레이터 |
| **합계** | **563 Flutter + 34 Rules = 597** | |

> 측정: `grep -rE "^\s*test\(" test/` = 440, `grep -rE "^\s*testWidgets\(" test/` = 123, `integration_test/` 4개.

## 테스트 파일 구조

```
test/
├── auth_repository_test.dart        # Repository 패턴 + Mock 주입
├── auth_service_test.dart
├── board_categories_test.dart
├── chat_id_test.dart
├── comment_input_bar_test.dart      # Widget — a11y 테스트 포함
├── conflict_dialog_test.dart
├── dday_manager_test.dart
├── dday_manager_extended_test.dart
├── deep_link_service_test.dart
├── delete_alert_dialog_test.dart
├── error_snackbar_test.dart
├── error_view_test.dart
├── event_attach_card_test.dart
├── exceptions_test.dart
├── fcm_payload_test.dart
├── grade_manager_test.dart
├── grade_provider_test.dart         # Provider test
├── grade_screen_widget_test.dart    # Widget test
├── input_sanitizer_test.dart
├── link_card_a11y_test.dart         # Widget — a11y 전용
├── meal_api_test.dart               # Unit (Completer 프리페치 검증)
├── meal_card_allergy_test.dart
├── meal_data_api_test.dart
├── meal_subject_model_test.dart
├── meal_test.dart
├── network_status_test.dart
├── notice_api_test.dart
├── notice_data_api_test.dart
├── offline_queue_manager_test.dart
├── poll_card_test.dart
├── post_card_golden_test.dart       # Golden
├── responsive_test.dart
├── schedule_data_test.dart
├── search_history_service_test.dart
├── search_tokens_test.dart          # Unit (2-gram 토크나이저)
├── secure_storage_service_test.dart # Unit (migrateFromPlain)
├── setting_data_test.dart
├── skeleton_test.dart
├── timetable_api_test.dart
├── timetable_cell_test.dart
├── timetable_data_api_test.dart
├── timetable_parse_test.dart
├── today_banner_test.dart
├── user_profile_test.dart
├── version_compare_test.dart
├── vote_button_test.dart            # Widget — a11y + 동작 테스트
├── widget_service_test.dart
├── widget_service_logic_test.dart
├── write_category_selector_test.dart
├── write_toggle_row_test.dart
├── helpers/                         # Mock 공통 유틸
└── goldens/                         # Golden 스냅샷 PNG

tests/firestore-rules/               # Rules 에뮬레이터 테스트 (Node.js)
integration_test/                    # e2e (선택)
```

> 총 53개 테스트 파일 (helpers/, goldens/ 디렉터리 제외).

## 계층별 상세

### 1. Unit (89개)
- 모델 직렬화 (`freezed` / `json_serializable`), 등급 변환, 급식 파싱
- 시간표 교시 계산, 검색 토크나이저 (2-gram), 검색 기록(SharedPreferences)
- secure_storage 마이그레이션
- 외부 의존 없음 (파일/네트워크/시간 모킹)

### 2. Provider (17개)
- `ProviderContainer` 생성 → Notifier `.future` await → state 단언
- **예시**:
  ```dart
  final container = ProviderContainer(overrides: [
    gradeRepositoryProvider.overrideWithValue(FakeGradeRepository()),
  ]);
  addTearDown(container.dispose);

  final exams = await container.read(examsProvider.future);
  expect(exams, isNotEmpty);
  ```
- `addTearDown(container.dispose)`로 ProviderContainer 누수 방지 ([기술과제 #12](./technical-challenges.md#12-위젯-테스트의-비결정적-timer-leak))

### 3. Widget (123 testWidgets)
- `ProviderScope(overrides: [...])`로 Mock Notifier 주입
- 로딩 / 에러 / 빈 상태 / 성공 분기 모두 검증
- **Timer Leak 방지**: 영구 로딩은 `Completer.future` 로 시뮬, 테스트 끝에 `complete()`
- **접근성(a11y) 테스트**: `link_card_a11y_test.dart`, `vote_button_test.dart` (a11y 그룹), `comment_input_bar_test.dart` (a11y 그룹) — Semantics 라벨, 탭 순서, 스크린리더 호환 검증

### 4. Golden (5개)
- `post_card_golden_test.dart` — PostCard 5종 변종 (기본/좋아요/공지/+N badge/익명+매니저뷰)
- `fake_cloud_firestore`로 Mock Firestore 주입
- **Tolerance comparator**로 플랫폼 폰트 렌더 미세 차이 흡수
- 업데이트: `flutter test --update-goldens`

### 5. Repository (8개)
- `setupServiceLocator()` + Mock 구현체 주입 → 정상/예외 분기 검증
- DI 점진적 마이그레이션 데모 ([ADR-07](./architecture-decisions.md#adr-07-di-getit--추상-repository))

### 6. Firestore Rules (34개)
- `tests/firestore-rules/` 디렉터리, Node.js
- `@firebase/rules-unit-testing` 라이브러리 + Firestore 에뮬레이터
- 시나리오:
  - 권한 우회 (비작성자의 글 수정, 타인 프로필 수정 등)
  - 카운터 ±1 delta 검증 (`validCounterDelta`)
  - 필드 위조 (비작성자가 `likes` 외 필드 수정 시도)
  - 채팅 참여자 아닌 사용자의 read/write 차단
  - 메시지 내용 수정 시도 차단 (삭제 필드만 허용)

## 실행법

### Flutter 테스트
```bash
# 전체
flutter test

# 커버리지 포함
flutter test --coverage

# Golden 업데이트
flutter test --update-goldens

# 특정 파일
flutter test test/search_tokens_test.dart

# 특정 그룹/이름
flutter test --name "2-gram"
```

### Firestore Rules 테스트
```bash
cd tests/firestore-rules
npm install
firebase emulators:exec --only firestore,auth --project hansol-test "npm test"
```

### Integration 테스트 (선택)
```bash
flutter test integration_test/
```

## Mock / Fake 패턴

| 대상 | 방식 |
|---|---|
| Firestore | `fake_cloud_firestore` |
| Firebase Auth | Mock + `setupServiceLocator` |
| Repository | Abstract + 테스트용 구현체 (GetIt 주입) |
| AsyncNotifier | `ProviderScope.overrides` + Mock Notifier |
| Timer | `Completer` 패턴 ([기술과제 #12](./technical-challenges.md#12-위젯-테스트의-비결정적-timer-leak)) |
| HTTP | 테스트용 `Client` 오버라이드 |

## CI 연계

두 GitHub Actions 워크플로우가 병렬 실행:

1. `.github/workflows/flutter.yml` — `flutter analyze` + `flutter test --coverage` + Codecov 업로드 + master push 시 APK 빌드
2. `.github/workflows/firestore-rules.yml` — `firebase emulators:exec ... npm test` (Node 20, Java 21, path 트리거)

상세는 [cicd-setup.md](./cicd-setup.md).

## 실행 시간 (실측)
- Flutter 전체 (`flutter test`): 563개 (`test` + `testWidgets`), 로컬 머신 기준 수 초~수십 초
- Integration (`integration_test/`): 4개, 디바이스/에뮬레이터 필요
- Rules (`firebase emulators:exec ... npm test`): 34개, Java 21 + Node 20

## PIPA + 4단계 역할 통합 시나리오 (수동)

자동화 테스트 대상이 아니라 **배포 전 수동 점검용** 체크리스트입니다. 실제 계정 4종(admin / manager / moderator / auditor / 일반)을 준비해 진행합니다.

### 가입 / 동의 플로우
- [ ] 신규 가입 — 약관 + 개인정보 + 14세 이상 모두 체크 → 가입 진행
- [ ] 약관 / 개인정보 미동의 → 가입 버튼 비활성
- [ ] 14세 미만 체크 → 가입 차단 메시지

### 정지 + 이의제기 (`appeals`)
- [ ] manager가 일반 사용자를 24시간 정지 → 정지 사용자가 글/댓글 작성 시도 → 차단
- [ ] 정지 사용자가 앱 `/appeal_screen` → 사유 입력 후 제출 → `appeals` 컬렉션 신규 문서 (`status: pending`)
- [ ] manager가 Admin Web `/appeals`에서 검토 → 승인 → 사용자 `suspendedUntil` 해제 + `appeals.status = approved`
- [ ] auditor 계정으로 `/appeals` 진입 → 목록 읽기 가능, 액션 버튼 비표시

### 데이터 권리 (`data_requests`)
- [ ] 사용자가 앱에서 데이터 요청 제출 (열람 / 이전 / 삭제) → `data_requests` 신규 문서
- [ ] manager가 Admin Web `/data-requests`에서 처리 → Functions가 ZIP 생성 + 서명 URL 반환 → `status: completed`
- [ ] 사용자 측에서 다운로드 링크 동작 확인, 7일 만료 후 링크 무효 확인

### 4단계 역할 권한 매트릭스
- [ ] **moderator**: `/posts` 삭제 가능, `/comments` 삭제 가능, `/users`/`/dashboard`/`/feedbacks` 메뉴 비표시
- [ ] **auditor**: `/admin-logs`, `/dashboard`, `/crashes`, `/feedbacks`, `/function-logs` 모두 읽기 가능 / 쓰기 시도 시 권한 오류
- [ ] **manager**: `/users` 역할 변경 가능 (admin 임명 제외), 정지/승인/삭제 가능
- [ ] **admin**: 다른 사용자에게 admin 임명 가능, 자신의 admin 해제 버튼 노출 확인

### `admin_logs` 기록
- [ ] 각 액션 후 Admin Web `/admin-logs`에서 해당 항목 확인:
  - `change_role` (with `previousRole`/`newRole`), `approve_user`, `reject_user`, `suspend_user` (with `hours`), `unsuspend_user`, `delete_user`, `delete_post`, `delete_comment`, `delete_feedback`
- [ ] `expiresAt` 필드가 `createdAt + 30일`로 정확히 설정
- [ ] (Blaze 한정) 30일 경과 항목이 TTL로 자동 삭제되는지 확인

### 커뮤니티 규정 (`community_rules`)
- [ ] manager가 Admin Web `/community-rules`에서 신규 버전 발행 → `community_rules` 신규 문서 + 버전 증가
- [ ] 사용자 앱이 새 버전 감지 → 재동의 다이얼로그 노출 → 동의 시 다음 사용 허용
- [ ] 미동의 시 메인 기능 차단 동작

상세 권한 매트릭스: [security.md](./security.md), 액션 로그 스키마: [admin-features.md](../features/admin-features.md#감사-로그-admin_logs).

## 새 테스트 추가 시
- 새 Riverpod Provider → Provider test 필수
- 새 Firestore 필드/규칙 변경 → Rules test 필수 (회귀 방지)
- 새 게시판 UI 변종 → Golden test 고려
- 모든 비동기 로직은 `Completer` / `addTearDown`으로 leak 방지

## 관련 문서
- [CI/CD 설정](./cicd-setup.md)
- [아키텍처 의사결정 일지](./architecture-decisions.md)
- [기술 과제](./technical-challenges.md)
