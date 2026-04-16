# 기여 가이드

> English: [CONTRIBUTING_en.md](./CONTRIBUTING_en.md)

한솔고 앱 프로젝트에 기여해주셔서 감사합니다. 이 문서는 브랜치/PR/코드 스타일/테스트 규칙을 정리합니다.

## 먼저 읽을 문서

새 기여자라면 이 순서로 문서를 훑으면 맥락이 잡힙니다.

1. [제품 개요](./docs/product-overview.md)
2. [아키텍처 개요](./docs/architecture-overview.md)
3. [아키텍처 의사결정 일지](./docs/architecture-decisions.md)
4. 작업할 피처의 상세: [공개](./docs/features/public-features.md) / [커뮤니티](./docs/features/community-features.md) / [개인](./docs/features/personal-features.md) / [관리자](./docs/features/admin-features.md)
5. [테스트 전략](./docs/testing.md)

## 개발 환경 준비

### 필수 도구
- Flutter SDK stable (≥ 3.x). `pubspec.yaml` 은 `sdk: '>=2.17.0 <4.0.0'` 범위
- Dart (Flutter 동봉)
- Node.js 20+ (Cloud Functions, Admin Web, rules 테스트)
- Firebase CLI (`npm install -g firebase-tools`)
- Java 17+ (Android 빌드), 21 (Firebase emulator)

### 더미 시크릿 파일 생성

`lib/api/nies_api_keys.dart`, `lib/firebase_options.dart`, `lib/api/kakao_keys.dart` 세 파일이 없으면 analyze/test가 실패합니다. CI 워크플로우의 heredoc 블록(`.github/workflows/flutter.yml`)을 참조해 더미 내용을 생성하거나, 실제 키를 받아 주입하세요.

실제 실행(앱 구동)까지 필요한 경우 `google-services.json`(Android) / `GoogleService-Info.plist`(iOS) 추가. [DEPLOY.md](./DEPLOY.md) 참조.

### 설치

```bash
flutter pub get
```

`build_runner` 코드 생성이 필요한 경우 (Riverpod 코드젠, Freezed, JSON 시리얼라이저):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
# 또는 watch 모드
flutter pub run build_runner watch --delete-conflicting-outputs
```

## 브랜치 & PR

### 브랜치 전략
- **기본 브랜치**: `master`
- **기능 브랜치**: `feature/<짧은-설명>` 또는 `fix/<짧은-설명>`, `docs/<짧은-설명>`
- 직접 master push 금지, PR을 거쳐 머지

### PR 체크리스트
- [ ] `flutter analyze --no-fatal-infos --no-fatal-warnings` 통과
- [ ] `flutter test` 전체 통과
- [ ] 규칙 변경 시 `tests/firestore-rules` 테스트 추가/업데이트
- [ ] 새 UI 변종은 Golden 테스트 고려
- [ ] 새 Provider는 Provider test 추가
- [ ] 스크린샷 변경 시 `screenshots/` 업데이트
- [ ] 관련 문서 동기화 (`docs/*.md`, README, USER_GUIDE 등)

### 커밋 메시지

기존 컨벤션 (한국어 요약, 핵심 주제 우선):

```
<주제>: <요약>

<필요 시 본문 설명>
```

실제 예시 (`git log --oneline` 참고):
- `Blaze 배포: Storage Rules + cleanupOldPosts + Functions 런타임 업그레이드`
- `README 민감 데이터 row D-day 제거 + Firestore Rules CI Java 21 업그레이드`
- `golden test: tolerance comparator로 platform font diff 흡수`
- `테스트 커버리지 확대 (Golden + SearchHistory)`

주제 예시: `README`, `golden test`, `Firestore rules`, `auth`, `build`, `docs`, `CI`.

## 코드 스타일

### Dart
- `analysis_options.yaml` + `flutter_lints ^4.0.0`
- `dart format .` 적용
- `custom_lint` + `riverpod_lint` 플러그인도 활용

### 주요 관례
- **Riverpod**: `@riverpod` 어노테이션 기반 코드 생성. 수동 `Provider<T>` 선언은 예외적 경우에만.
- **레이어 분리**: Widget → Provider → Manager/Repository. Widget에서 Firestore 직접 접근 금지.
- **DI**: Manager/Repository는 GetIt으로, Widget은 Riverpod으로. 혼용 규칙은 [ADR-07](./docs/architecture-decisions.md#adr-07-di-getit--추상-repository).
- **비공개 위젯 최소화**: 파일이 200줄을 넘으면 Stateless Widget으로 분리 ([기술과제 #13](./docs/technical-challenges.md#13-statefulwidget-1400-라인--stateless-composition-refactoring)).

### TypeScript (Admin Web)
- `admin-web/` 에서 동일 원칙. Next.js 14 App Router, Tailwind, Firebase Auth.
- ESLint/Prettier는 `admin-web/` 하위의 설정을 따릅니다.

## 테스트

```bash
# 전체
flutter test

# 커버리지
flutter test --coverage

# Golden 업데이트
flutter test --update-goldens

# Rules (Node)
cd tests/firestore-rules
npm install
firebase emulators:exec --only firestore,auth --project hansol-test "npm test"
```

새 기능 시 최소 다음 중 하나는 추가:
- 비즈니스 로직 → Unit
- Provider → Provider test
- 새 rules 분기 → Rules test
- 재사용 UI → Widget / Golden

자세한 전략: [testing.md](./docs/testing.md).

## 문서 업데이트

기능/아키텍처 변경 시 해당 문서를 함께 수정합니다. 대응표:

| 변경 대상 | 업데이트할 문서 |
|---|---|
| 새 기능 | `docs/features/*.md`, `USER_GUIDE.md`, README 피처 섹션 |
| 보안 규칙 | `firestore.rules` + `docs/security.md` + `docs/data-model.md` |
| 아키텍처 결정 | `docs/architecture-decisions.md`에 새 ADR 추가 |
| 주요 기술 과제 해결 | `docs/technical-challenges.md` |
| 배포 절차 | `DEPLOY.md` |

한국어 파일을 업데이트했으면 `_en.md` 영문 쌍도 동기화해주세요. 상단 "Last sync: YYYY-MM-DD" 주석을 갱신하면 리뷰가 쉬워집니다.

## 코드 리뷰

- PR 크기는 가능한 300줄 이내로 분할
- 리뷰어 지정 시 해당 영역 오너에게 (감지 안 되면 @Monkshark)
- CI가 모두 그린인 상태에서만 머지

## 이슈 리포팅

- 버그: 재현 단계, 예상 결과, 실제 결과, 환경 (OS/Flutter/앱 버전)
- 기능 제안: 문제 정의, 제안 솔루션, 대안 검토

## 관련 문서
- [배포 가이드](./DEPLOY.md)
- [엔드유저 가이드](./USER_GUIDE.md)
- [테스트 전략](./docs/testing.md)
- [CI/CD 설정](./docs/cicd-setup.md)
