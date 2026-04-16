# 개인 기능 (성적 / 개인일정 / 프로필)

> English: [personal-features_en.md](./personal-features_en.md)

사용자 개인 데이터를 다루는 기능을 묶었습니다. 성적은 완전 로컬, 개인일정은 sqflite, 프로필은 Firestore에 저장됩니다.

## 성적 관리

### 탭 구조

- **수시(내신) / 정시(모의고사)** 탭 분리, 스와이프 전환
- **내신**: 5등급제 + 성취도(A~E) 병기, 2022 개정 교육과정 적용
- **모의고사**: 2022 개정 수능 과목 (국/수/영/한국사/통합사회/통합과학 + 제2외국어)
- **사설 모의고사** 추가 가능

### 시각화

- **추이 그래프**: CustomPainter 꺾은선 ([ADR-05](../guides/architecture-decisions.md#adr-05-차트-custompainter-직접-구현))
  - 모드 토글: 등급 / 원점수 / 백분위 / 표준점수
  - 등급 스케일 반전(낮을수록 좋음) 올바르게 표시
- **과목별 목표** 등급(수시 0.1단위) / 목표 백분위(정시) 분리 설정
- **백분위 → 등급 자동 변환** (등급컷 기준 점선 표시)
- **영어/한국사** 절대평가 과목 백분위 목표 제외
- 과목별 고정 색상 (`lib/data/` 정의)

### 저장소

- **성적 로컬 전용 저장** — 서버 전송 없음 (`flutter_secure_storage`, [ADR-02](../guides/architecture-decisions.md#adr-02-민감-데이터-저장소-flutter_secure_storage))
- Android Keystore / iOS Keychain 위임
- 기존 평문 데이터 → 첫 실행 시 1회 자동 마이그레이션

**관련 파일**: `lib/screens/sub/grade_screen.dart`, `grade_input_screen.dart`, `lib/providers/grade_provider.dart`, `test/grade_manager_test.dart`, `test/secure_storage_service_test.dart`

## 개인일정

- **커스텀 월간 캘린더**와 연동 (공개 기능 참조)
- 하루/연속 일정, 6색 + 원형 컬러피커
- **sqflite** 저장 — 오프라인 우선, 범위 쿼리 빠름
- NEIS 학사일정과 시각적 구분 (점 vs 바)

**관련 파일**: `test/schedule_data_test.dart`

## D-day

- 목표일까지 남은 일수 표시
- **홈 화면 핀 고정** 지원
- sqflite 저장 (일정과 동일 DB)

**관련 파일**: `lib/screens/sub/dday_screen.dart`, `test/dday_manager_test.dart`

## 프로필 / 설정

- **프로필 사진** (Cloud Storage 업로드, 256px 압축)
- 개인정보 동의, 온보딩 → 로그인 플로우
- 알림 5카테고리 on/off (→ [커뮤니티 기능의 알림](./community-features.md#알림-시스템))
- 테마 (라이트/다크/시스템)
- 급식 알림 시간 설정

**관련 파일**: `lib/screens/auth/profile_edit_screen.dart`, `profile_setup_screen.dart`, `lib/screens/sub/setting_screen.dart`, `notification_setting_screen.dart`, `lib/screens/sub/onboarding_screen.dart`

## 새 학년 프로필 업데이트

- 재학생/교사만 **3월에 정보 업데이트 팝업** 표시
- 학년/반/번호 등 새 학년 정보 입력 유도
- **역할 변경 불가** (관리자만 역할 변경 가능 — [security.md](../guides/security.md) 참조)

## 회원 탈퇴

- **이중 확인** 다이얼로그
- **완전 삭제 순서** ([기술과제 #10](../guides/technical-challenges.md#10-계정-삭제-순서-문제-auth--firestore-권한-소실)):
  1. Firestore `users/{uid}` 문서 삭제 (인증 상태 유지 중)
  2. 연관 하위 컬렉션 (`subjects`, `notifications`, `sync`) 일괄 삭제
  3. Cloud Storage 프로필 사진 삭제
  4. `user.delete()`로 Auth 계정 삭제
- 이름/프로필 사진/성적은 로컬 포함 완전 파기

## 관련 문서
- [공개 기능](./public-features.md)
- [커뮤니티 기능](./community-features.md)
- [관리자 기능](./admin-features.md)
- [인증 & 접근](../guides/account-and-access.md)
- [보안 모델](../guides/security.md)
