# CI/CD Setup

> 한국어: [cicd-setup.md](./cicd-setup.md)

GitHub Actions-based CI/CD pipeline. Two workflows run in parallel; both must pass before merging to master.

## Workflows

| File | Trigger | Role |
|---|---|---|
| `.github/workflows/flutter.yml` | `push`/`pull_request` → `master` | analyze + test + APK build |
| `.github/workflows/firestore-rules.yml` | rules paths changed | Firestore rules unit tests |

Both use `concurrency: cancel-in-progress: true` so a newer push cancels older runs on the same branch.

## flutter.yml Pipeline

### Job 1 — `analyze-and-test`

| Step | Content |
|---|---|
| Setup Flutter | `subosito/flutter-action@v2`, stable channel, cache enabled |
| **Create dummy secret files** | `lib/api/nies_api_keys.dart`, `lib/firebase_options.dart`, `lib/api/kakao_keys.dart` generated with dummy values — CI has no real keys |
| Install deps | `flutter pub get` |
| Verify formatting | `dart format --output=none --set-exit-if-changed .` (warn only, non-fatal) |
| **Analyze** | `flutter analyze --no-fatal-infos --no-fatal-warnings` |
| **Run tests with coverage** | `flutter test --coverage --reporter=expanded` |
| Upload coverage to Codecov | `codecov/codecov-action@v4`, flag `unittests` |
| Upload coverage artifact | `coverage/lcov.info` retained 14 days |

### Job 2 — `build-android` (conditional)

- Condition: `github.event_name == 'push' && github.ref == 'refs/heads/master'` → **master pushes only**
- `needs: analyze-and-test` — runs only if prior job succeeds
- Also generates `android/app/google-services.json` with a dummy project id
- Java 17, Flutter stable
- **Debug APK build** (`--debug --target-platform android-arm64`)
- Artifact: `build/app/outputs/flutter-apk/app-debug.apk`, 7 days

### Dummy Secret Strategy

CI builds/tests without real NEIS / Firebase / Kakao keys. Reasons:
- No keys committed to the repo
- Tests validate logic without network calls
- APK is built with a dummy config (not for real execution)

Local development needs the real key files — see [DEPLOY_en.md](../../DEPLOY_en.md).

## firestore-rules.yml Pipeline

Path-triggered — only runs if any of these changed:
- `firestore.rules`
- `tests/firestore-rules/**`
- `.github/workflows/firestore-rules.yml`

| Step | Content |
|---|---|
| Setup Node | v20 |
| Setup Java | v21 (Firebase emulator requirement) |
| Install Firebase CLI | `npm install -g firebase-tools` |
| Install test deps | `cd tests/firestore-rules && npm install` |
| **Run rules tests** | `firebase emulators:exec --only firestore,auth --project hansol-test "npm test"` |

34 rules tests complete in roughly 4 seconds.

## Badges

README top:

```md
[![Flutter CI](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/flutter.yml/badge.svg)](...)
[![Firestore Rules Tests](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/firestore-rules.yml/badge.svg)](...)
```

## Reproduce Locally

```bash
# CI analyze
flutter analyze --no-fatal-infos --no-fatal-warnings

# CI test
flutter test --coverage

# CI rules
cd tests/firestore-rules
npm install
firebase emulators:exec --only firestore,auth --project hansol-test "npm test"

# CI APK (debug only — no release key)
flutter build apk --debug --target-platform android-arm64
```

## Codecov

- Coverage reporting based on `lcov.info`
- `fail_ci_if_error: false` — upload failures don't fail the CI
- Auto-comments coverage delta on PRs

## Merge Rules (recommended)

- **Required checks**: `Flutter CI / Analyze + Test (ubuntu-latest)` passing
- **When rules paths touched**: `Firestore Rules Tests / Firestore Rules Unit Tests` passing
- **APK build** failure is non-blocking (notification only)

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Formatting issues found` warning | needs `dart format` | run `dart format .` locally and commit |
| analyze failure | error (not info/warning) | reproduce locally with same flags |
| Rules test breaks right before merge | rules/app logic out of sync | when changing `firestore.rules`, update `tests/firestore-rules/*.spec.js` together |
| APK build `google-services.json` missing | workflow dummy block missing | check the heredoc in the workflow |

## See Also
- [Testing Strategy](./testing_en.md)
- [Deployment Guide](../../DEPLOY_en.md)
- [Contributing Guide](../../CONTRIBUTING_en.md)
