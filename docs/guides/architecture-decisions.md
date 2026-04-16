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

- **`test()` 단위 (440)**: 모델/유틸/파서/Provider/Repository/Golden 포함. `ProviderContainer`로 위젯 없이 AsyncNotifier 검증, Mock 주입으로 외부 의존 0
- **`testWidgets()` 위젯 (80)**: `ProviderScope.overrides`로 Mock notifier 주입, 로딩/에러/빈 분기 검증
- **Golden (`matchesGoldenFile`)**: PostCard 스냅샷 비교 (`fake_cloud_firestore` + tolerance comparator) — `test()` 내부 포함
- **Integration (4)**: `integration_test/`에서 앱 네비게이션 E2E
- **Firestore Rules (34)**: `@firebase/rules-unit-testing` + 에뮬레이터로 보안 규칙 자체를 검증. 코드 변경 없이 rules 회귀 방지
- **버린 옵션**: 통합 테스트 전체 의존 (Firebase Auth 실로그인) — CI 비용 ↑, 플레이크 ↑
- **합계**: 524 (Flutter) + 34 (Rules) = **558개**. 상세 분류는 [testing.md](./testing.md) 참조.
