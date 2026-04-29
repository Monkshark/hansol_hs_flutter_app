# 아키텍처 의사결정 일지 (ADR)

> English: [architecture-decisions_en.md](./architecture-decisions_en.md)

각 결정은 *왜 다른 후보가 아니라 이 선택인가* 를 짧게 정리합니다.

---

## ADR-01. 상태관리: Riverpod 2.5 (vs Provider / BLoC / GetX)

- **선택 이유**: 컴파일 타임 안전성(`ref.watch`), `family`/`autoDispose` 조합, AsyncNotifier로 로딩/에러 분기 코드를 줄여줌
- **버린 옵션**:
  - *Provider* — 상태가 깊어질수록 `Consumer` boilerplate 증가, AsyncValue 미지원
  - *BLoC* — Stream 기반이라 단순 CRUD에도 Event/State class 양산, 학습 곡선
  - *GetX* — DI/네비/i18n까지 한 패키지에 묶여 있어 lock-in 위험
- **트레이드오프**: `riverpod_generator` 코드 생성 의존, `ref` 객체를 비위젯 코드에 노출하지 않도록 별도 Manager 계층 유지
- **관련 파일**: `lib/providers/*.dart`, `pubspec.yaml` (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)

---

## ADR-02. 민감 데이터 저장소: flutter_secure_storage (vs SharedPreferences)

- **대상**: 성적 (사용자 식별 가능 + 학교 맥락에서 민감)
- **선택 이유**: Android Keystore / iOS Keychain 위임으로 OS 수준 암호화. SharedPreferences는 평문 XML/plist
- **마이그레이션**: 기존 평문 데이터 → 첫 실행 시 1회 자동 이전(`migrateFromPlain`), 구 키 삭제. 회귀 방지용 unit test 8개
- **버린 옵션**: 전체 Firestore 동기화 — 성적은 *완전 로컬*이 사용자 신뢰에 더 부합
- **관련 파일**: `lib/data/secure_storage_service.dart`, `test/secure_storage_service_test.dart`

---

## ADR-03. 게시판 검색: 클라이언트 n-gram 인덱싱 (vs Algolia / Typesense / 클라이언트 필터)

- **선택 이유**: Firestore는 LIKE/full-text 미지원. 외부 검색 인프라 추가 없이 글 저장 시 제목+본문을 2-gram으로 분해해 `searchTokens` 배열에 저장 → `array-contains-any` 쿼리. 한국어 단어 구분 모호성에도 강함
- **상한**: doc당 200 토큰 / query당 10 토큰 (Firestore array-contains-any 한계 = 30)
- **버린 옵션**:
  - *Algolia/Typesense* — 월 비용 + 인프라 추가, 학교 앱 규모엔 과도
  - *클라이언트 필터* — 페이지네이션된 20건만 검색됨 → 전체 검색 불가능
- **남은 한계**: 토큰 매칭이라 false positive 가능 → fetch 후 클라이언트 substring 1차 필터
- **관련 파일**: `test/search_tokens_test.dart`, `test/search_history_service_test.dart`

---

## ADR-04. 좋아요 카운터: Map<uid,bool> + 비정규화 int (vs Map only / int only)

- **선택 이유**: 두 표현을 동시에 보유. `likes: {uid: true}` 는 "내가 눌렀는가" O(1) 조회용, `likeCount: int` 는 인기글 정렬용 (orderBy 가능)
- **동기화**: `_toggleLike`에서 `FieldValue.increment(±1)` + Map dot-path 업데이트를 단일 트랜잭션으로 묶음. legacy 글은 `_ensureLikesMap`에서 Map size로 lazy backfill
- **rules 검증**: `validCounterDelta('likeCount')`에 `resource.data.get(field, 0)` 사용하여 기존 글 호환 + ±1 delta 강제
- **버린 옵션**:
  - *Map only* — 카운트 정렬 불가 (Firestore가 array length 기준 orderBy 불가)
  - *int only* — "내가 눌렀는가" 확인용 별도 컬렉션 필요 → 읽기 비용 ↑
- **관련 파일**: `firestore.rules` (`validCounterDelta`), `firestore.indexes.json` (`likeCount DESC + createdAt DESC`)

---

## ADR-05. 차트: CustomPainter 직접 구현 (vs fl_chart / syncfusion)

- **선택 이유**: 성적 추이 그래프는 등급 스케일 반전(낮을수록 좋음), 영어/한국사 절대평가 분기, 등급컷 점선, 과목별 색상 등 *비표준 요구사항*이 많음. 라이브러리 wrapper에 맞추는 것보다 Canvas로 직접 그리는 것이 간단
- **장점**: 의존성 0개, APK 사이즈 영향 0
- **트레이드오프**: 새 차트 추가 시 재사용성 낮음 → 향후 공부 통계 등에서 차트가 늘어나면 fl_chart 도입 재검토
- **관련 파일**: `lib/screens/sub/grade_screen.dart` (CustomPainter 구현부)

---

## ADR-06. 저장소 분담: SQLite / Firestore / SecureStorage / Cloud Storage

| 저장소 | 용도 | 이유 |
|---|---|---|
| **sqflite** | 개인 일정 (시간/색상/연속 일자) | Row 단위 시간 범위 쿼리 + 오프라인 우선 |
| **Firestore** | 글/댓글/채팅/신고/사용자 프로필 | 실시간 sync + 다중 클라이언트 + Cloud Functions 트리거 |
| **SecureStorage** | 성적 | OS 암호화 + 완전 로컬 |
| **Cloud Storage** | 게시글·프로필 이미지 | CDN + 직접 다운로드 URL |

각각 명확한 단일 용도 → 코드에서 "이 데이터는 어디에 있는가" 헷갈리지 않음. 상세 스키마는 [data-model.md](./data-model.md) 참조.

---

## ADR-07. DI: GetIt + 추상 Repository (vs Riverpod Provider만 / get_it 직접만)

- **선택 이유**: Riverpod은 위젯 트리 의존, 비위젯 코드(Manager, Cloud Functions 트리거 핸들러)에서 쓰기 어색. GetIt은 service locator로 어디서나 호출 가능
- **혼용 규칙**: 위젯 → Riverpod, Manager/Repository → GetIt. 테스트는 `setupServiceLocator()` / `resetServiceLocator()` 로 Mock 주입
- **버린 옵션**:
  - *Riverpod Provider 단독* — 비위젯 코드에서 ref 전달이 번거로움
  - *get_it 단독* — 위젯 rebuild가 자동으로 안 됨
- **관련 파일**: `test/auth_repository_test.dart` (점진적 DI 마이그레이션 데모)

---

## ADR-08. 테스트 전략: Unit + Provider + Widget + Rules 4계층

- **`test()` 단위 (470)**: 모델/유틸/파서/Provider/Repository/Golden 포함. `ProviderContainer`로 위젯 없이 AsyncNotifier 검증, Mock 주입으로 외부 의존 0
- **`testWidgets()` 위젯 (89)**: `ProviderScope.overrides`로 Mock notifier 주입, 로딩/에러/빈 분기 검증
- **Golden (`matchesGoldenFile`)**: PostCard 스냅샷 비교 (`fake_cloud_firestore` + tolerance comparator) — `test()` 내부 포함
- **Integration (4)**: `integration_test/`에서 앱 네비게이션 E2E
- **Firestore Rules (85)**: `@firebase/rules-unit-testing` + 에뮬레이터로 보안 규칙 자체를 검증. 4단계 역할(`user`/`moderator`/`auditor`/`manager`/`admin`) + PIPA 컬렉션(`appeals`/`data_requests`/`community_rules`) 권한 매트릭스 포함
- **버린 옵션**: 통합 테스트 전체 의존 (Firebase Auth 실로그인) — CI 비용 ↑, 플레이크 ↑
- **합계**: 563 (Flutter) + 85 (Rules) = **648개**. 상세 분류는 [testing.md](./testing.md) 참조.

---

## ADR-09. 권한 모델: 4단계 역할 + Firebase Auth custom claims (vs Firestore role 필드 단일 검사)

- **배경**: 초기 모델은 `role: "user" | "manager"` 2단계. manager는 신고 처리부터 정지까지 전부 가능 → 학생 운영자가 "정지" 같은 무거운 행동을 떠안게 됨. 동시에 Firestore 보안 규칙은 매 요청마다 `get(/databases/.../users/$uid).data.role`로 사용자 문서를 추가 조회 → 게시글 1건 읽을 때마다 읽기 1회 추가
- **선택**: 역할을 `user` / `moderator` / `auditor` / `manager` / `admin` 5단계로 분리 (실질 4단계 권한 + 일반 사용자). 권한은 Firebase Auth **custom claims**로 ID 토큰에 박아 `request.auth.token.role`로 검사 → 보안 규칙 `get()` 0회
- **권한 매트릭스**:
  - `moderator` — 신고 처리, 게시글/댓글 숨김. 정지 불가
  - `auditor` — 모든 신고/로그/통계 읽기 전용. 쓰기 없음 (교사 감사 권한 시나리오)
  - `manager` — 정지, 공지 고정, 사용자 승인
  - `admin` — 모든 권한 + 다른 사용자 권한 변경
- **마이그레이션**: 기존 28명 사용자에 대해 `users` 컬렉션을 순회하며 `setCustomUserClaims({role, approved})` 1회 백필 (`scripts/backfill-claims.js` 로컬 admin SDK)
- **트레이드오프**: 권한 변경 직후 클라이언트는 `getIdTokenResult(true)` 강제 갱신 필요 / 권한 검사 로직이 토큰 발급 시점과 동기화돼야 함
- **버린 옵션**: Firestore role 필드 단일 검사 — 매 요청 추가 읽기, 권한 검사가 데이터 읽기에 비례
- **관련 파일**: `firestore.rules`, `functions/index.js` (`onUserUpdated`/`backfillCustomClaims`), `tests/firestore-rules/test/rules.test.js`

---

## ADR-10. PIPA 컴플라이언스: TTL 컬렉션 + 자동 라이프사이클 (vs 수동 청소 / soft delete 플래그)

- **배경**: 한국 개인정보 보호법(PIPA)은 (1) 처리 결과 이의신청권 (2) 데이터 다운로드권 (3) 명시된 커뮤니티 규칙 — 세 가지를 보장하라고 요구. "삭제 버튼"이 아니라 **보관 기한이 끝난 데이터를 개입 없이 사라지게 만드는 것**이 진짜 핵심
- **선택**: 새 컬렉션 3개 (`appeals`, `data_requests`, `community_rules`) 추가 + 거의 모든 새 컬렉션에 `expiresAt` 필드 + Firestore TTL 정책. 만료 시각이 지나면 Firestore가 알아서 문서 삭제
- **TTL 정책**:
  - `appeals.expiresAt` — 90일
  - `data_requests.expiresAt` — 30일
  - `admin_logs.expiresAt` — 1년 (감사 로그)
- **데이터 익스포트**: `createDataExport` Cloud Function이 사용자 게시글/댓글/신고/채팅을 JSON으로 묶어 Storage 업로드, 다운로드 링크 이메일 발송, 만료 후 `purgeExpiredExports` 일일 청소
- **트레이드오프**: TTL은 1회/일 정도로 비결정적 시점에 삭제 → 정확한 만료 시각 보장 안 됨 (PIPA 요건 충족엔 충분)
- **버린 옵션**:
  - *수동 청소* — 사람이 매주 청소하는 시스템은 결국 안 청소됨
  - *soft delete 플래그* — 데이터가 사라지지 않으니 PIPA의 "보관 의무 종료 후 파기" 요건 미충족
- **관련 파일**: `firestore.rules`, `firestore.indexes.json`, `functions/index.js` (`createDataExport`/`purgeExpiredExports`), `lib/screens/appeal/`, `lib/screens/data_request/`, `lib/screens/community_rules/`

---

## ADR-11. 대시보드 카운터: `app_stats/totals` 비정규화 (vs 클라이언트 collection.count())

- **배경**: 관리자 대시보드는 `posts`, `users`, `reports` 컬렉션의 총 개수와 일별 추세를 보여줘야 함. 클라이언트가 매번 컬렉션 전체를 fetch하면 1k 사용자 기준 매 페이지 진입마다 수천 회 읽기
- **선택**: Cloud Functions 트리거(`onPostCreated`/`onUserCreated`/`onReportCreated`)에서 `app_stats/totals` 단일 문서에 `FieldValue.increment(1)`. 일별 추세는 `app_stats/daily_<YYYY-MM-DD>` 문서에 동일하게 누적. 대시보드는 카운터 문서 1개만 읽음
- **트레이드오프**: 트리거가 누락되면 카운터가 어긋남 → `backfillStats` HTTP 함수로 1회 재계산 가능
- **버린 옵션**: `collection.count()` aggregation — 매 호출마다 컬렉션 스캔, 비용 절감 효과 거의 없음
- **관련 파일**: `functions/index.js` (`incrementStat`/`backfillStats`), `admin-web/app/page.tsx`
