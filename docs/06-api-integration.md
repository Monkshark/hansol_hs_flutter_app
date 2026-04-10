# 외부 API 연동 가이드

> 각 클래스의 함수별 상세 설명은 [API Reference](api/README.md)를 참조한다.

---

## NEIS 교육정보 API

교육부 [NEIS 교육정보 개방 포털](https://open.neis.go.kr/)에서 제공하는 공개 API이다.
급식, 시간표, 학사일정 데이터를 조회한다.

### API 키

`lib/api/nies_api_keys.dart` (gitignore 대상)에 저장:

```dart
class NiesApiKeys {
  static const String apiKey = 'YOUR_NEIS_API_KEY';
}
```

NEIS API 키는 **공개 API 키**로, 클라이언트에 포함되어도 보안 위험이 낮다.
(요청 수 제한만 존재, 민감 데이터 접근 없음)

---

### 급식 API → [meal_data_api.md](api/meal_data_api.md)

**엔드포인트**: `https://open.neis.go.kr/hub/mealServiceDietInfo`

| 파라미터 | 설명 |
|----------|------|
| `KEY` | API 인증 키 |
| `ATPT_OFCDC_SC_CODE` | 시도교육청코드 |
| `SD_SCHUL_CODE` | 표준학교코드 |
| `MLSV_YMD` | 급식일자 (YYYYMMDD) |
| `MMEAL_SC_CODE` | 식사코드 (1=조식, 2=중식, 3=석식) |

**핵심 전략**: 월간 프리페치 + 차등 TTL (정상 24h / 빈 데이�� 5min)

---

### 시간표 API → [timetable_data_api.md](api/timetable_data_api.md)

**엔드포인트**: `https://open.neis.go.kr/hub/hisTimetable` (고등학교)

| 파라미터 | 설명 |
|----------|------|
| `GRADE` | 학년 |
| `CLASS_NM` | 반 |
| `TI_FROM_YMD` | 시작일 |
| `TI_TO_YMD` | 종료일 |

**핵심 전략**: 이번 주 → 다음 주 → 지난 주 폴백 + 과목 조합 프리로드

---

### 학사일정 API → [notice_data_api.md](api/notice_data_api.md)

**엔드포인트**: `https://open.neis.go.kr/hub/SchoolSchedule`

| 파라미터 | 설명 |
|----------|------|
| `AA_FROM_YMD` | 시작일 |
| `AA_TO_YMD` | 종료일 |

**핵심 전략**: 12h 캐시 + 90일 범위 예정 이벤트 조회

---

## Kakao OAuth 연동

### 아키텍처

```
Flutter 앱                    Cloud Function                 Kakao 서버
    │                              │                              │
    ├── Kakao SDK 로그인 ──────────────────────────────────────→ │
    │← access_token ─────────────────────────────────────────────┤
    │                              │                              │
    ├── POST /kakaoCustomAuth ────→│                              │
    │   { token: access_token }    ├── GET /v2/user/me ──────────→│
    │                              │←── 사용자 정보 ──────────────┤
    │                              │                              │
    │                              ├── Firebase Auth 사용�� 조회/생성
    │                              ├── Custom Token 발급
    │←── { firebaseToken } ────────┤
    │                              │
    ├── signInWithCustomToken()    │
    └── 로그인 완료                │
```

### Kakao SDK 설정

`lib/api/kakao_keys.dart` (gitignore 대상):

```dart
class KakaoKeys {
  static const String nativeAppKey = 'YOUR_KAKAO_NATIVE_APP_KEY';
}
```

### UID 형식

Kakao 사용자는 Firebase에서 `kakao:{kakaoUserId}` 형태의 UID를 사용한다.

### 주의사항

- Kakao 계정의 **이메일은 비즈앱 심사 없이는 제공되지 않음**
- 이메일 없이도 앱 사용 가능 (계정 삭제 시 이름으로 확인)
- 프로필 사진은 Kakao에서 제공하면 Firestore에 자동 저장

---

## 소셜 로그인 요약

각 로그인 메서드의 코드 레벨 상세는 [auth_service.md](data/auth_service.md) 참조.

| 프로바이더 | 방식 | Cloud Function 필요 |
|-----------|------|-------------------|
| Google | `GoogleSignIn` → Firebase credential | X |
| Apple | nonce + SHA256 → OAuthProvider | X |
| Kakao | Kakao SDK → Cloud Function → Custom Token | O (`kakaoCustomAuth`) |
| GitHub | `signInWithProvider` (Firebase 내장) | X |

---

## Firebase Cloud Messaging → [fcm_service.md](notification/fcm_service.md)

### 토픽 구조

```
board_new_post      ← 전체 게시판 알림 (마스터 토글)
board_free          ← 자유 게시판
board_question      ← 질문 게시판
board_info          ← 정보공유 게시판
board_lost          ← 분실물 게시판
board_council       ← 학생회 게시판
board_club          ← 동아리 게시판
board_popular       ← 인기글 알림
```

한글 카테고리명은 영문 키로 변환 (FCM 토픽은 영문만 허용).

### 딥링크 타입

| type | 동작 |
|------|------|
| `comment` / `new_post` | → `PostDetailScreen(postId)` |
| `chat` | → Firestore에서 상대 정보 로드 → `ChatRoomScreen` |
| `account` | 앱만 열림 (무시) |

---

## 로컬 급식 알림 → [daily_meal_notification.md](notification/daily_meal_notification.md)

- 평일(월~금) 반복 알림, 조식/중식/석식 개별 ON/OFF
- 타임존 처리 (Asia/Seoul)
- 알림 본문에 당일 메뉴 미리보기 포함
- 알레르기 번호 자동 제거

---

## 앱 업데이트 체크 → [update_checker.md](notification/update_checker.md)

Firestore `app_config/version` 문서 기반:

| 필드 | 설명 |
|------|------|
| `min` | 최소 지원 버전 → 이 미만이면 **필수** 업데이트 (닫기 불가) |
| `latest` | 최신 버전 → 이 미만이면 **선택** 업데이트 ("나중에" 가능) |
| `updateUrlAndroid` / `updateUrlIOS` | 플랫폼별 스토어 URL |

---

## 인앱 팝업 공지 → [popup_notice.md](notification/popup_notice.md)

Firestore `app_config/popup` 문서 기반. 긴급/이벤트/일반 타입별 색상 분리. "오늘 안 보기" 지원.
