# 테스트 전략

> English: [testing_en.md](./testing_en.md)

4계층 테스트 체계 (Unit + Provider + Widget + Golden + Firestore Rules)로 총 **180개** 테스트를 유지합니다.

## 한눈에 보기

| 계층 | 개수 | 특징 |
|---|---|---|
| Unit | 89 | 모델/유틸/파서 — 외부 의존 0 |
| Provider | 17 | `ProviderContainer`로 AsyncNotifier 직접 검증 |
| Widget | 17 | `ProviderScope.overrides` + Mock Notifier |
| Golden | 5 | PostCard 스냅샷 PNG 비교 |
| Repository | 8 | GetIt 기반 Mock 주입 데모 |
| Firestore Rules | 34 | `@firebase/rules-unit-testing` + 에뮬레이터 |
| Integration | 10 | `integration_test/` (선택적) |
| **합계** | **146 Flutter + 34 Rules = 180** | |

## 테스트 파일 구조

```
test/
├── auth_repository_test.dart       # Repository 패턴 + Mock 주입
├── auth_service_test.dart
├── dday_manager_test.dart
├── grade_manager_test.dart
├── grade_provider_test.dart        # Provider test
├── grade_screen_widget_test.dart   # Widget test
├── meal_api_test.dart              # Unit (Completer 프리페치 검증)
├── meal_test.dart
├── post_card_golden_test.dart      # Golden
├── schedule_data_test.dart
├── search_history_service_test.dart
├── search_tokens_test.dart         # Unit (2-gram 토크나이저)
├── secure_storage_service_test.dart# Unit (migrateFromPlain)
├── timetable_api_test.dart
├── widget_service_test.dart
├── helpers/                        # Mock 공통 유틸
└── goldens/                        # Golden 스냅샷 PNG

tests/firestore-rules/              # Rules 에뮬레이터 테스트 (Node.js)
integration_test/                   # e2e (선택)
```

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

### 3. Widget (17개)
- `ProviderScope(overrides: [...])`로 Mock Notifier 주입
- 로딩 / 에러 / 빈 상태 / 성공 분기 모두 검증
- **Timer Leak 방지**: 영구 로딩은 `Completer.future` 로 시뮬, 테스트 끝에 `complete()`

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
- Flutter Unit/Widget/Provider/Golden: **약 3초**, 131 tests, 로컬 머신 기준
- Rules: **약 4초**, 34 tests, `firebase emulators:exec`

## 새 테스트 추가 시
- 새 Riverpod Provider → Provider test 필수
- 새 Firestore 필드/규칙 변경 → Rules test 필수 (회귀 방지)
- 새 게시판 UI 변종 → Golden test 고려
- 모든 비동기 로직은 `Completer` / `addTearDown`으로 leak 방지

## 관련 문서
- [CI/CD 설정](./cicd-setup.md)
- [아키텍처 의사결정 일지](./architecture-decisions.md)
- [기술 과제](./technical-challenges.md)
