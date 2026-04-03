# 한솔고등학교 앱

> 세종시 한솔고등학교 학생·교사·졸업생을 위한 통합 학교 플랫폼

Flutter 기반 모바일 앱 + Next.js 관리자 대시보드로 구성된 풀스택 프로젝트입니다. NEIS 공공데이터 API 연동, Firebase 실시간 데이터베이스, 역할 기반 권한 시스템, 푸시 알림, 1:1 채팅 등 실서비스 수준의 기능을 구현했습니다.

## 기술 스택

| 분류 | 기술 |
|------|------|
| Mobile | **Flutter** (Dart) — Android / iOS |
| State | **Riverpod** — 상태 관리 |
| Admin Web | **Next.js 14** — App Router, TypeScript, Tailwind CSS |
| Backend | **Firebase** — Auth, Firestore, Storage, FCM, Crashlytics |
| Server | **Cloud Functions** (Node.js) — 푸시 알림, Kakao OAuth, 정지 해제 스케줄러 |
| External API | **NEIS 공공데이터** — 급식, 시간표, 학사일정 |
| Local | **sqflite** (일정 DB), **SharedPreferences** (설정/캐시) |
| Auth | **Google**, **Apple**, **Kakao**, **GitHub** OAuth |
| CI | **GitHub Actions** — Flutter analyze + test |
| Test | **flutter_test** — Unit Test (18 tests) |

## 주요 기능

### 급식 조회
- NEIS API 기반 조식/중식/석식 메뉴 실시간 조회
- 월간 프리페치 캐시 (24시간/빈 결과 5분), Completer 패턴으로 동시 요청 방지
- 급식 카드 탭 → 이미지 공유, 영양정보 바텀시트 (알레르기 유발 식품 표시)
- 급식 알림에 메뉴 미리보기 포함

### 시간표
- 1학년: 반별 자동 조회 / 2-3학년: 선택과목 기반 맞춤 시간표
- **교사 전용 시간표**: 학년 탭(1/2/3학년) → 과목 스와이프 → 중복 반 선택 가능, 수업만 표시
- 과목 충돌 자동 감지 + 해결 팝업, 과목별 컬러 커스터마이징 (원형 피커)
- 현재 교시 실시간 표시 (1분 갱신, 프로그레스 바)
- **오늘 요일 하이라이트** + 빈 교시 자동 제거
- 선택과목 저장 확인 + 미저장 뒤로가기 경고
- 새 학기(3월) 시간표 + 선택과목 자동 리셋 (재학생만)

### 일정 관리
- 월간 캘린더 (한국어, 토/일 색상 구분), sqflite 기반 개인일정 CRUD
- NEIS 학사일정 자동 표시 (6개월, 연속 중복 제거)
- D-day 관리 + 홈 화면 핀 고정

### 게시판
- 카테고리: 자유 / 질문 / 정보공유 / 분실물 / 학생회 / 동아리
- 커서 기반 페이지네이션 (20개씩, 무한 스크롤, 당겨서 새로고침)
- 공지 시스템 (최대 3개, 상단 고정, 관리자 전용)
- 댓글 + 대댓글 (들여쓰기), 글쓴이 댓글 구분 (파란 배경 + 뱃지)
- 익명 번호제: 익명1/익명2/익명(글쓴이), Firestore Transaction
- 투표 첨부 (최대 6선택지, 실시간 결과 바), 추천/비추천
- 일정 공유 ("내 일정에 추가" 원클릭), 사진 첨부 (640px 압축, CachedNetworkImage)
- 분실물 해결 처리 (찾았어요 → 해결 뱃지)
- **게시글 북마크/저장** (북마크 아이콘 토글)
- **이미지 전체화면 뷰어** (핀치 줌, InteractiveViewer)
- **키워드 검색** (제목/내용 필터)
- **스켈레톤 로딩 UI** (shimmer 애니메이션)
- **더보기 메뉴**: 바텀시트 UI (아이콘 + 텍스트, 삭제/신고 빨간색 강조)
- 신고 (중복 방지), 사용자 차단, 글 자동 삭제 (1년 TTL)
- Rate Limiting (글 30초, 댓글 10초 쿨타임)
- 내 활동: **내가 쓴 글 / 내가 쓴 댓글 / 저장한 글** 3탭
- 글 등록 시 게시판 자동 새로고침

### 1:1 채팅
- 실명 유저끼리만 채팅 가능 (익명 게시글에서는 채팅 메뉴 미표시)
- 게시글 상세에서 **채팅 아이콘 버튼**으로 바로 채팅 시작
- 실시간 메시지 (Firestore onSnapshot, limit 30)
- **읽음 표시**: 상대방이 읽으면 "읽음" 텍스트 표시
- **메시지 삭제**: 길게 누르기 → 나만 삭제 / 같이 삭제 (안 읽었고 1시간 이내만)
- **채팅방 나가기**: 시스템 메시지 ("OO님이 나갔습니다") + 상대방 채팅 유지
- 읽지 않은 메시지 수 뱃지
- 채팅 목록: 마지막 메시지 + 시간 + 읽지않은 수 표시
- **스켈레톤 로딩 UI**

### 알림 시스템
- **알림 설정 화면**: 카테고리별 개별 on/off
- 급식 알림: 로컬 스케줄링 (조식/중식/석식, 시간 설정, 메뉴 미리보기)
- 인앱 알림: 댓글/답글/계정 알림 (벨 아이콘 + 읽지 않은 알림 뱃지)
- 푸시 알림: FCM + Cloud Functions
  - 댓글 알림 (글 작성자) — 개별 on/off
  - **대댓글 알림** (부모 댓글 작성자에게도 발송, 중복 방지) — 개별 on/off
  - 새 글 알림 (토픽 구독) — 개별 on/off
  - 가입/승인/거절/정지/**정지 해제**/역할변경 알림 — 개별 on/off
  - **채팅 메시지 푸시 알림** — 개별 on/off
- **정지 만료 자동 해제**: Cloud Functions 스케줄러 (매시간 체크)

### 건의사항
- **앱 건의사항 & 버그 제보**: 텍스트(1000자) + 사진 첨부(최대 3장)
- **학생회 건의사항**: 동일 UI, 별도 컬렉션
- 상태 관리: 대기중 → 확인됨 → 해결됨 (관리자 변경)
- 관리자 앱 내 조회 (Admin 탭) + 웹 대시보드 조회

### 인증 & 권한
- **Google / Apple / Kakao / GitHub** OAuth 로그인
  - Kakao: Cloud Functions 커스텀 토큰
  - GitHub: Firebase signInWithProvider
  - 로그인 버튼: **SVG 브랜드 로고** 사용
- 신분 선택: 재학생 / 졸업생 / 교사 / 학부모
- 가입 요청 → 관리자 승인 플로우
- **개인정보 수집·이용 동의** (가입 시 필수 체크)
- 3단계 역할: **user** → **manager** → **admin**
- 계정 정지 (1시간~30일, 남은 시간 표시, 자동 해제)
- **내 계정 화면**: 프로필 사진 변경 (카메라/갤러리, 256px 압축, Firebase Storage) + 내 정보 카드(읽기전용) + 회원 탈퇴
- 회원 탈퇴 (이중 확인, Firestore + Auth + 하위 컬렉션 삭제)
- **관리자 삭제 시**: Firebase Auth 계정 + 하위 컬렉션 자동 삭제 (Cloud Functions)
- 새 학기(3월) 프로필 강제 업데이트, 삭제된 계정 자동 로그아웃
- **온보딩 → 로그인** 자연스러운 플로우 (첫 실행 시)
- **개인정보 처리방침** 앱 내 표시

### 관리자 대시보드 (Next.js)
- 통계 카드 (사용자/게시글/신고/오늘 활동)
- 게시글 관리: 검색, 상세 (본문/이미지/댓글/투표), 공지 등록/해제
- 사용자 관리: 3탭 (승인 대기/사용자/정지), 역할 임명, 상세 페이지
- 관리자 감사 로그 (승인/거절/삭제/정지/역할변경 이력)
- **크래시 로그**: 앱 크래시 실시간 모니터링 (에러/스택트레이스/유저/시간)
- **건의사항 관리**: 앱 건의/학생회 건의 탭 전환, 상세 패널, 상태 변경
- 익명 글/댓글 실명 확인 (관리자 전용)
- 로그인 방식 표시 (Google/Apple/Kakao/GitHub)
- 모바일 반응형 (햄버거 메뉴, 테이블 가로 스크롤)

### 관리자 앱 내 기능
- Admin 화면 6탭: 신고 / 승인 대기 / 사용자 / 정지 / 앱 건의 / 학생회

## 프로젝트 구조

```
hansol_hs_flutter_app/
│
├── lib/                        # Flutter 모바일 앱
│   ├── api/                    #   NEIS API 통신 (급식, 시간표, 학사일정)
│   ├── data/                   #   모델, DB, Auth, 설정
│   ├── providers/              #   Riverpod Providers (Auth, Theme)
│   ├── notification/           #   로컬 알림, FCM, 업데이트 체크
│   ├── screens/
│   │   ├── auth/               #   로그인 (4 OAuth), 프로필 설정, 내 계정
│   │   ├── board/              #   게시판, 관리자, 알림, 북마크
│   │   ├── chat/               #   1:1 채팅 (목록, 채팅방, 유틸)
│   │   ├── main/               #   메인 3탭 (급식/홈/일정)
│   │   └── sub/                #   설정, D-day, 시간표, 온보딩, 교사 시간표,
│   │                           #   알림 설정, 건의사항
│   ├── styles/                 #   테마 컬러 (라이트/다크)
│   └── widgets/                #   공용 위젯 (스켈레톤 등)
│
├── admin-web/                  # Next.js 관리자 대시보드
│   ├── app/                    #   App Router (대시보드/게시글/사용자/크래시/건의사항)
│   ├── components/             #   Sidebar, StatsCard, Badge
│   └── lib/                    #   Firebase, Auth, Types, Utils
│
├── functions/                  # Cloud Functions
│   └── index.js                #   푸시 알림, Kakao OAuth, 채팅 푸시,
│                               #   대댓글 알림, 정지 해제 스케줄러, 계정 삭제
│
├── assets/                     # 앱 리소스
│   ├── icons/                  #   SVG 로그인 아이콘 (Google/Apple/Kakao/GitHub)
│   └── images/                 #   앱 이미지
│
├── firestore.rules             # Firestore 보안 규칙 (필드 단위 검증)
├── test/                       # Unit Tests (18 tests)
├── .github/workflows/          # GitHub Actions CI
└── admin-static/               # 레거시 관리자 (HTML/JS)
```

## 아키텍처

**Flutter App** (Android / iOS)
- ← NEIS API (급식, 시간표, 학사일정)
- ↔ **Firebase** (Auth, Firestore, Storage, FCM, Crashlytics)
- **Riverpod** 상태 관리

**Next.js Admin** (TypeScript + Tailwind CSS)
- ↔ **Firebase** (동일 Firestore 공유)
- 크래시 로그 + 건의사항 모니터링

**Cloud Functions** (Node.js)
- ← Firestore 트리거 (댓글/대댓글/사용자/채팅 이벤트)
- ← HTTP (Kakao OAuth 토큰 검증)
- ← Scheduler (매시간 정지 만료 체크)
- → FCM 푸시 알림 발송 (알림 설정 체크 후)

## 보안

- Firestore 보안 규칙: 역할 기반 접근 제어, role/suspendedUntil 직접 변조 차단
- **게시글 update 필드 단위 검증**: 투표/추천/북마크는 인증 유저 허용, 본문 수정은 작성자/관리자만
- 게시글/댓글 읽기: 인증 유저만 허용
- 게시글 삭제: 작성자 또는 관리자만
- Firebase config 환경변수 분리 (`.env.local`, `.gitignore`)
- API 키 Git 히스토리 완전 제거 (`git-filter-repo`)
- 입력값 길이 제한, 중복 신고 방지, HTTP 타임아웃 10초
- Rate Limiting: 글 30초, 댓글 10초 쿨타임
- Cloud Functions: 사용자 승인 상태 검증 + **알림 설정 체크** 후 발송
- 관리자 감사 로그 (모든 관리 행위 Firestore 기록)
- 크래시 로그 (Firebase Crashlytics + Firestore 기록)
- 글 만료 (Firestore TTL), 이미지 자동 압축 (640px / 프로필 256px)
- 사용자 차단 (blockedUsers 필드)
- 개인정보 수집·이용 동의 (가입 시 필수)
- 관리자 계정 삭제 시 Firebase Auth + 하위 컬렉션 자동 정리

## 예상 운영 비용 (1,000명 기준)

| 항목 | 무료 한도 | 예상 비용/월 |
|------|----------|------------|
| Firebase Auth | 50K MAU | $0 |
| Firestore | 1.5M 읽기/일 | $0~3 |
| Cloud Functions | 2M 호출/월 | $0 |
| Scheduler | 매시간 | $0 |
| Storage | 5GB | $0 |
| FCM | 무제한 | $0 |
| Crashlytics | 무제한 | $0 |
| **합계** | | **$0~3** |
