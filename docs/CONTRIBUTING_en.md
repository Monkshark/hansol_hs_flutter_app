# Contributing Guide

> 한국어: [CONTRIBUTING.md](./CONTRIBUTING.md)

Thanks for contributing to the Hansol HS app. This document covers branching, PRs, code style, and testing.

## Read First

New contributors should skim these in order to build context:

1. [Product Overview](https://monkshark.github.io/hansol_hs_flutter_app/#guides/product-overview_en.md)
2. [Architecture Overview](https://monkshark.github.io/hansol_hs_flutter_app/#guides/architecture-overview_en.md)
3. [Architecture Decisions (ADRs)](https://monkshark.github.io/hansol_hs_flutter_app/#guides/architecture-decisions_en.md)
4. Target feature detail: [Public](https://monkshark.github.io/hansol_hs_flutter_app/#features/public-features_en.md) / [Community](https://monkshark.github.io/hansol_hs_flutter_app/#features/community-features_en.md) / [Personal](https://monkshark.github.io/hansol_hs_flutter_app/#features/personal-features_en.md) / [Admin](https://monkshark.github.io/hansol_hs_flutter_app/#features/admin-features_en.md)
5. [Testing Strategy](https://monkshark.github.io/hansol_hs_flutter_app/#guides/testing_en.md)

## Dev Environment

### Prerequisites
- Flutter SDK stable (≥ 3.x). `pubspec.yaml` declares `sdk: '>=2.17.0 <4.0.0'`
- Dart (bundled with Flutter)
- Node.js 20+ (Cloud Functions, Admin Web, rules tests)
- Firebase CLI: `npm install -g firebase-tools`
- Java 17+ (Android build), Java 21 (Firebase emulator)

### Dummy Secret Files

Analyze/test fails without three files: `lib/api/nies_api_keys.dart`, `lib/firebase_options.dart`, `lib/api/kakao_keys.dart`. Either copy the heredoc blocks from the CI workflow (`.github/workflows/flutter.yml`) or inject real keys.

To actually run the app, also add `google-services.json` (Android) / `GoogleService-Info.plist` (iOS). See [DEPLOY_en.md](./DEPLOY_en.md).

### Install

```bash
flutter pub get
```

If codegen is needed (Riverpod generator, Freezed, JSON serializer):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
# or watch
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Branching & PRs

### Branch Strategy
- **Default branch**: `master`
- **Feature branches**: `feature/<short-desc>`, `fix/<short-desc>`, `docs/<short-desc>`
- No direct push to master — open a PR.

### PR Checklist
- [ ] `flutter analyze --no-fatal-infos --no-fatal-warnings` passes
- [ ] `flutter test` all green
- [ ] If rules changed, `tests/firestore-rules` tests updated
- [ ] New UI variants: consider golden tests
- [ ] New Providers: add provider tests
- [ ] Screenshots updated if UI changed (`screenshots/`)
- [ ] Related docs synced (`docs/*.md`, README, USER_GUIDE, etc.)

### Commit Messages

A single Korean summary line. Do not use prefix tags like `fix:`, `docs:`, or `<topic>:`.

```
<summary>

<optional body>
```

Rules:
- Body in Korean, but keep technical terms / variable / class / file / library names in English (`Riverpod`, `Firestore`, `StreamBuilder`, `index`, `lazy load`, etc.)
- Join multiple changes with ` + `
- Single-line title by default; add a body only for large changes (refactors, migrations)

Real examples (from `git log --oneline`):
- `Riverpod 마이그레이션 + 대형 파일 refactoring + 테스트 강화`
- `댓글 대댓글 위치 수정 + mention 중복 표시 수정 + refresh + Firestore index 정의`
- `관리자 화면 StreamBuilder → FutureBuilder 전환, ExpansionTile 자식 lazy load`
- `테스트 커버리지 확대 (Golden + SearchHistory)`

## Code Style

### Dart
- `analysis_options.yaml` + `flutter_lints ^4.0.0`
- Apply `dart format .`
- `custom_lint` + `riverpod_lint` plugins also enforced

### Core Conventions
- **Riverpod**: `@riverpod` annotation with codegen. Manual `Provider<T>` only in exceptional cases.
- **Layer separation**: Widget → Provider → Manager/Repository. Widgets must not touch Firestore directly.
- **DI**: Managers/Repositories via GetIt, widgets via Riverpod. Mixing rules: [ADR-07](./docs/guides/architecture-decisions_en.md#adr-07-di-getit--abstract-repository).
- **Minimize private widgets**: if a file exceeds ~200 lines, extract Stateless widgets. See [Technical Challenge #13](./docs/guides/technical-challenges_en.md#13-statefulwidget-1400-lines--stateless-composition-refactoring).

### TypeScript (Admin Web)
- Same principles under `admin-web/`. Next.js 14 App Router, Tailwind, Firebase Auth.
- ESLint/Prettier config lives under `admin-web/`.

## Testing

```bash
# all
flutter test

# coverage
flutter test --coverage

# update goldens
flutter test --update-goldens

# rules (Node)
cd tests/firestore-rules
npm install
firebase emulators:exec --only firestore,auth --project hansol-test "npm test"
```

For every new feature, add at least one of:
- Unit (business logic)
- Provider test
- Rules test (for any new rule branch)
- Widget / Golden (for reusable UI)

Full strategy: [testing_en.md](https://monkshark.github.io/hansol_hs_flutter_app/#guides/testing_en.md).

## Documentation Updates

Keep docs in sync with feature/architecture changes:

| Change | Update |
|---|---|
| New feature | `docs/features/*.md`, `USER_GUIDE.md`, README feature section |
| Security rules | `firestore.rules` + `docs/security_en.md` + `docs/data-model_en.md` |
| Architecture decision | New ADR in `docs/architecture-decisions_en.md` |
| Notable engineering fix | `docs/technical-challenges_en.md` |
| Deployment step | `DEPLOY_en.md` |

If you update a Korean file, sync the paired `_en.md`. Updating a "Last sync: YYYY-MM-DD" marker at the top helps reviewers.

## Code Review

- Keep PRs ≤ ~300 lines where possible
- Assign a reviewer from the area owner (@Monkshark if unsure)
- Merge only after CI is fully green

## Issue Reporting

- Bugs: reproduction steps, expected, actual, environment (OS / Flutter / app version)
- Feature proposals: problem statement, proposed solution, alternatives considered

## Related Docs
- [Deployment Guide](./DEPLOY_en.md)
- [User Guide](./USER_GUIDE_en.md)
- [Testing Strategy](https://monkshark.github.io/hansol_hs_flutter_app/#guides/testing_en.md)
- [CI/CD Setup](https://monkshark.github.io/hansol_hs_flutter_app/#guides/cicd-setup_en.md)
