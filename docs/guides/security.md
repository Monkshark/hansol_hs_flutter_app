# 보안 모델

> English: [security_en.md](./security_en.md)

Firestore 보안 규칙, 역할 기반 접근 제어, 개인정보 보호 장치를 한 곳에 정리합니다. 실제 규칙 파일은 `firestore.rules`, 테스트는 `tests/firestore-rules/`입니다.

## 핵심 원칙

1. **Firestore Rules가 단일 진실 소스** — 앱과 Admin Web이 같은 규칙 하에서 동작
2. **역할은 서버에만 저장** — `users/{uid}.role`. 클라이언트는 참조만, 변경 불가
3. **필드 단위 검증** — 작성자 외 사용자도 인터랙션 필드만 수정 가능
4. **민감 데이터는 서버에 저장하지 않음** — 성적은 OS 키체인에만

## Helper 함수 (firestore.rules)

```
function isSignedIn() { return request.auth != null; }

function isAdmin() {
  return isSignedIn() &&
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role == 'admin';
}

function isAdminOrManager() {
  return isSignedIn() && (
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role in ['admin', 'manager']
  );
}

function changedKeys() {
  return request.resource.data.diff(resource.data).affectedKeys();
}

function isInteractionUpdate() {
  return changedKeys().hasOnly(
    ['likes', 'dislikes', 'likeCount', 'dislikeCount',
     'pollVoters', 'commentCount',
     'anonymousMapping', 'anonymousCount', 'bookmarkedBy']
  );
}

function validCounterDelta(field) {
  return !(field in changedKeys()) || (
    request.resource.data[field] is int &&
    request.resource.data[field] >= 0 &&
    request.resource.data[field] - resource.data.get(field, 0) >= -1 &&
    request.resource.data[field] - resource.data.get(field, 0) <= 1
  );
}
```

## 컬렉션별 규칙 요약

### `users/{uid}`
- **read**: 본인 또는 manager/admin
- **create**: 인증 사용자
- **update**: 본인은 `role`/`suspendedUntil`/`approved` 불변 조건으로, manager/admin은 자유
- **delete**: 본인 또는 admin
- **서브컬렉션**: `subjects`, `sync` 는 본인만; `notifications`는 본인만 read/update/delete하되 create는 누구나 (관리자 알림 발송 허용)

### `posts/{postId}`
- **read**: 공개
- **create**: `authorUid == auth.uid` + 제목 1~200자 + 본문 ≤5000자
- **update**: 작성자 자유 OR 비작성자는 `isInteractionUpdate()` 필드 + `validCounterDelta(±1)`
- **delete**: 작성자 또는 manager/admin

### `chats/{chatId}` + 메시지
- 참여자(`participants` 배열)만 read/write
- 메시지 update는 삭제 필드(`deleted`, `deletedFor`)만 허용 — 내용 위변조 차단

### `reports`, `admin_logs`, `function_logs`
- `reports.create` 인증 사용자, 읽기/삭제 관리자 전용
- `admin_logs` / `function_logs` 관리자 전용

### `app_config/{key}`
- 읽기 공개 (버전 체크 / 팝업 공지), 쓰기 관리자 전용

## Rate Limiting

| 대상 | 방식 |
|---|---|
| 글 작성 | 클라이언트 30초 쿨타임, 규칙은 제목/본문 길이만 |
| 댓글 작성 | 클라이언트 10초 쿨타임 |
| 신고 중복 | `(postId, reporterUid)` 복합 인덱스로 중복 저장 차단 |

클라이언트 우회 가능성이 있어 **핵심 방어선은 Rules의 필드 단위 검증**입니다.

## Cloud Functions 보안

- `kakaoCustomAuth`: zod 스키마(`KakaoAuthSchema`)로 입력 검증, Kakao API 검증 후 Firebase custom token 발급
- 푸시 알림 트리거: 발송 전 수신자 `users/{uid}.notiXxx` 필드 체크 ([기술과제 #7](./technical-challenges.md#7-cloud-functions-알림-설정-개별-제어-server-side-filtering))
- 오류는 `function_logs` 컬렉션에 기록 (`logError` 헬퍼)

## 민감 데이터 처리

### 성적 — 로컬 전용
- `flutter_secure_storage` 사용 → Android Keystore / iOS Keychain
- 서버 업로드 없음, Cloud Backup 없음
- 기존 평문 SharedPreferences → 첫 실행 시 1회 마이그레이션 후 구키 삭제

### 프로필 사진
- Cloud Storage 업로드 전 **256px 압축**
- 탈퇴 시 Storage 파일 함께 삭제

### 게시글 이미지
- **1080px 압축 + EXIF/GPS 제거** (`flutter_image_compress`)
- Storage 업로드, URL을 Firestore에 저장

### OAuth 전용 인증
- 비밀번호 저장 없음 (Google / Apple / Kakao / GitHub)
- Kakao만 커스텀 토큰 브릿지 (Firebase Auth가 직접 지원 안 함)

## 개인정보 보호

- **개인정보 처리방침** 앱 내 표시 (`assets/privacy_policy.html`)
- 가입 시 동의 필수
- 최소 수집 원칙: 이름/학번/이메일/프로필 사진만 (학교 맥락 필수 정보)
- **회원 탈퇴 시 즉시 파기** — 관련 컬렉션 + Storage + Auth 계정 순서로 완전 삭제 ([기술과제 #10](./technical-challenges.md#10-계정-삭제-순서-문제))
- **TTL 자동 삭제**: 오래된 로그/신고는 `cleanupOldPosts` 스케줄러로 만료 처리

## 크래시 / 감사

- **Crashlytics** (Firebase 콘솔)
- `function_logs` (Functions 오류 미러)
- `admin_logs` (모든 관리 행위: 누가, 언제, 무엇을, 이전→이후)

## 테스트

- `tests/firestore-rules/`: `@firebase/rules-unit-testing` + 에뮬레이터 34개 테스트
- 권한 우회 / 카운터 위조 / 필드 위조 시나리오를 CI 단계에서 검증
- 실행법: [testing.md](./testing.md) + [cicd-setup.md](./cicd-setup.md)

## 관련 문서
- [데이터 모델](./data-model.md)
- [아키텍처 의사결정 일지](./architecture-decisions.md)
- [인증 & 접근](./account-and-access.md)
- [배포 가이드](../DEPLOY.md) — 규칙 배포 명령
