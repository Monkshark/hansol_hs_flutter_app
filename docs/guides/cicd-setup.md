# CI/CD 설정

> English: [cicd-setup_en.md](./cicd-setup_en.md)

GitHub Actions 기반 CI/CD 파이프라인을 정리합니다. 두 워크플로우가 병렬로 돌며, 둘 다 통과해야 master에 머지됩니다.

## 워크플로우 목록

| 파일 | 트리거 | 역할 |
|---|---|---|
| `.github/workflows/flutter.yml` | `push`/`pull_request` → `master` | analyze + test + APK 빌드 |
| `.github/workflows/firestore-rules.yml` | 규칙 경로 변경 시만 | Firestore Rules 단위 테스트 |

두 워크플로우 모두 `concurrency: cancel-in-progress: true` 로 같은 브랜치의 이전 실행을 자동 취소합니다.

## flutter.yml 파이프라인

### Job 1 — `analyze-and-test`

| 단계 | 내용 |
|---|---|
| Setup Flutter | `subosito/flutter-action@v2`, stable 채널, 캐시 활성화 |
| **Create dummy secret files** | `lib/api/nies_api_keys.dart`, `lib/firebase_options.dart`, `lib/api/kakao_keys.dart` 를 더미 값으로 생성 — 실제 키는 CI에 없음 |
| Install deps | `flutter pub get` |
| Verify formatting | `dart format --output=none --set-exit-if-changed .` (경고만, 실패는 non-fatal) |
| **Analyze** | `flutter analyze --no-fatal-infos --no-fatal-warnings` |
| **Run tests with coverage** | `flutter test --coverage --reporter=expanded` |
| Upload coverage to Codecov | `codecov/codecov-action@v4`, flag `unittests` |
| Upload coverage artifact | `coverage/lcov.info` 14일 보관 |

### Job 2 — `build-android` (conditional)

- 조건: `github.event_name == 'push' && github.ref == 'refs/heads/master'` → **master push 시에만**
- `needs: analyze-and-test` → 선행 Job 성공해야 실행
- 더미 파일 추가로 `android/app/google-services.json` 생성 (프로젝트 id는 dummy)
- Java 17, Flutter stable
- **Debug APK 빌드** (`--debug --target-platform android-arm64`)
- `build/app/outputs/flutter-apk/app-debug.apk` 를 artifact로 7일 보관

### 더미 시크릿 전략

CI는 실제 NEIS / Firebase / Kakao 키 없이 빌드/테스트만 수행합니다. 핵심 이유:
- 키를 레포에 커밋하지 않음
- 테스트는 네트워크 호출 없이 로직 검증
- APK도 dummy config로 생성 (실제 실행용 아님)

로컬 개발에서는 실제 키 파일을 생성해야 합니다. [DEPLOY.md](../../DEPLOY.md) 참조.

## firestore-rules.yml 파이프라인

경로 트리거 — 다음 파일 변경 시만 실행:
- `firestore.rules`
- `tests/firestore-rules/**`
- `.github/workflows/firestore-rules.yml`

| 단계 | 내용 |
|---|---|
| Setup Node | v20 |
| Setup Java | v21 (Firebase emulator 요구사항) |
| Install Firebase CLI | `npm install -g firebase-tools` |
| Install test deps | `cd tests/firestore-rules && npm install` |
| **Run rules tests** | `firebase emulators:exec --only firestore,auth --project hansol-test "npm test"` |

34개 rules 테스트가 약 4초 안에 완료됩니다.

## 배지 연동

README 최상단 배지:

```md
[![Flutter CI](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/flutter.yml/badge.svg)](...)
[![Firestore Rules Tests](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/firestore-rules.yml/badge.svg)](...)
```

## 로컬에서 동일하게 재현

```bash
# CI의 analyze 단계
flutter analyze --no-fatal-infos --no-fatal-warnings

# CI의 test 단계
flutter test --coverage

# CI의 rules 단계
cd tests/firestore-rules
npm install
firebase emulators:exec --only firestore,auth --project hansol-test "npm test"

# CI의 APK 빌드 단계 (release 키 없이 디버그만)
flutter build apk --debug --target-platform android-arm64
```

## Codecov

- `lcov.info` 기반 커버리지 보고
- `fail_ci_if_error: false` — 업로드 실패가 CI 실패로 이어지지 않음
- PR에 커버리지 변화 자동 코멘트

## 머지 규칙 (권장)

- **Required checks**: `Flutter CI / Analyze + Test (ubuntu-latest)` 성공
- **Required when rules path touched**: `Firestore Rules Tests / Firestore Rules Unit Tests` 성공
- **APK 빌드** 실패는 블로킹 아님 (notification 용도)

## 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `Formatting issues found` 경고 | `dart format` 필요 | 로컬에서 `dart format .` 후 커밋 |
| analyze 실패 | info/warning이 아닌 error | 로컬에서 `flutter analyze` 동일 플래그로 확인 |
| Rules 테스트 머지 직전 깨짐 | 규칙-앱 로직 동기화 안 됨 | `firestore.rules` 변경 시 `tests/firestore-rules/*.spec.js` 함께 수정 |
| APK 빌드 실패 `google-services.json` | dummy 파일 생성 누락 | workflow의 heredoc 블록 확인 |

## 관련 문서
- [테스트 전략](./testing.md)
- [배포 가이드](../../DEPLOY.md)
- [기여 가이드](../../CONTRIBUTING.md)
