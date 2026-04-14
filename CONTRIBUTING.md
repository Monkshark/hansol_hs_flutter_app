# Contributing

한솔고등학교 앱에 기여해주셔서 감사합니다.

## 시작하기

### 요구사항

- Flutter 3.x / Dart 3.x
- Firebase CLI (`firebase-tools`)
- Node.js 20+ (Cloud Functions, Firestore Rules 테스트)
- Android Studio 또는 VS Code

### 로컬 설정

```bash
git clone https://github.com/Monkshark/hansol_hs_flutter_app.git
cd hansol_hs_flutter_app
flutter pub get
```

Firebase 설정 파일(`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`)은 각자 Firebase 프로젝트에서 생성해야 합니다.

## 개발 워크플로우

### 브랜치 전략

1. `master`에서 feature 브랜치를 생성합니다
2. 작업 완료 후 PR을 올립니다
3. CI 통과 + 코드 리뷰 후 머지합니다

```bash
git checkout -b feature/my-feature
# 작업 ...
git push -u origin feature/my-feature
```

### 커밋 메시지

한국어로 작성하되, 변수명/기술 용어는 영어 그대로 유지합니다.

```
급식 캐시 TTL 로직 수정: 빈 결과 5분 → 10분

- MealDataApi._getFromCache 타이머 조정
- 관련 테스트 업데이트
```

### 코드 스타일

- `flutter analyze` 에러 0 유지
- 기존 코드 패턴을 따릅니다 (Riverpod, GetIt, static API 클래스 등)
- 새 기능에는 테스트를 포함합니다

## 테스트

```bash
# Flutter 테스트
flutter test

# Firestore Rules 테스트 (에뮬레이터 필요)
cd tests/firestore-rules
npm test
```

- `flutter test`는 344개 테스트가 모두 통과해야 합니다
- API 테스트는 `MockClient` + `NetworkStatus.testOverride` 패턴을 사용합니다

## PR 가이드라인

- PR 제목은 간결하게 (70자 이내)
- 변경 내용과 테스트 방법을 설명합니다
- 스크린샷이 필요한 UI 변경은 첨부합니다
- `flutter analyze` 에러가 없어야 합니다

## 버그 리포트

[Issues](https://github.com/Monkshark/hansol_hs_flutter_app/issues)에 다음 정보와 함께 등록해주세요:

- 재현 단계
- 기대 동작 vs 실제 동작
- 기기 정보 (OS 버전, 앱 버전)
- 스크린샷 (가능하면)

## 라이선스

이 프로젝트는 [MIT License](LICENSE)를 따릅니다.
