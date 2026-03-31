# 한솔고등학교 앱

> 세종시 한솔고등학교 학생·교사·졸업생을 위한 통합 학교 플랫폼

Flutter 기반 모바일 앱 + Next.js 관리자 대시보드로 구성된 풀스택 프로젝트입니다. NEIS 공공데이터 API 연동, Firebase 실시간 데이터베이스, 역할 기반 권한 시스템, 푸시 알림 등 실서비스 수준의 기능을 구현했습니다.

## 기술 스택

| 분류 | 기술 |
|------|------|
| Mobile | **Flutter** (Dart) — Android / iOS |
| Admin Web | **Next.js 14** — App Router, TypeScript, Tailwind CSS |
| Backend | **Firebase** — Auth, Firestore, Storage, FCM |
| Server | **Cloud Functions** (Node.js) — 이벤트 기반 푸시 알림 |
| External API | **NEIS 공공데이터** — 급식, 시간표, 학사일정 |
| Local | **sqflite** (일정 DB), **SharedPreferences** (설정/캐시) |

## 주요 기능

### 급식 조회
- NEIS API 기반 조식/중식/석식 메뉴 실시간 조회
- 월간 프리페치 캐시 (24시간/빈 결과 5분), 평일 탭하여 강제 새로고침
- 급식 카드 탭 → 이미지 공유, 영양정보 바텀시트 (알레르기 유발 식품 표시)

### 시간표
- 1학년: 반별 자동 조회 / 2-3학년: 선택과목 기반 맞춤 시간표
- 과목 충돌 자동 감지 + 해결 팝업, 과목별 컬러 커스터마이징 (원형 피커)
- 현재 교시 실시간 표시 (1분 갱신, 프로그레스 바)
- 새 학기(3월) 시간표 + 선택과목 자동 리셋

### 일정 관리
- 월간 캘린더 (한국어, 토/일 색상 구분), sqflite 기반 개인일정 CRUD
- NEIS 학사일정 자동 표시 (6개월, 연속 중복 제거)
- D-day 관리 + 홈 화면 핀 고정

### 게시판
- 카테고리 (자유/질문/정보공유), 검색, 내 활동 모아보기
- 공지 시스템 (최대 3개, 상단 고정, 관리자 전용)
- 댓글 + 대댓글 (들여쓰기), 익명 모드 (계정 연결 유지)
- 투표 첨부 (최대 6선택지, 실시간 결과 바), 추천/비추천
- 일정 공유 ("내 일정에 추가" 원클릭), 사진 첨부 (640px 자동 압축, 최대 5장)
- 신고 (중복 방지), 글 자동 삭제 (1년 TTL)
- 입력 길이 제한 (제목 200, 내용 5000, 댓글 1000자)

### 알림 시스템
- 급식 알림: 로컬 스케줄링 (조식/중식/석식, 시간 설정)
- 인앱 알림: 댓글/답글/계정 알림 (벨 아이콘 + 읽지 않은 알림 뱃지)
- 푸시 알림: FCM + Cloud Functions (댓글, 새 글, 가입/승인/거절/정지)

### 인증 & 권한
- Google OAuth 로그인, 신분 선택 (재학생/졸업생/교사/학부모)
- 가입 요청 → 관리자 승인 플로우
- 3단계 역할: **user** → **manager** → **admin**
- 계정 정지 (1시간~30일, 남은 시간 실시간 표시, 자동 해제)
- 새 학기(3월) 프로필 강제 업데이트, 삭제된 계정 자동 로그아웃

### 관리자 대시보드 (Next.js)
- 통계 카드 (사용자/게시글/신고/오늘 활동)
- 게시글 관리: 검색, 상세 (본문/이미지/댓글/투표), 공지 등록/해제
- 사용자 관리: 3탭 (승인 대기/사용자/정지), 역할 임명, 상세 페이지
- 신고/댓글 관리, 앱 버전 설정
- 모바일 반응형 (햄버거 메뉴, 테이블 가로 스크롤)

## 프로젝트 구조

```
hansol_hs_flutter_app/
│
├── lib/                        # Flutter 모바일 앱
│   ├── api/                    #   NEIS API 통신 (급식, 시간표, 학사일정)
│   ├── data/                   #   모델, DB, Auth, 설정
│   ├── notification/           #   로컬 알림, FCM, 업데이트 체크
│   ├── screens/
│   │   ├── auth/               #   로그인, 프로필 설정 (신분 선택)
│   │   ├── board/              #   게시판, 관리자, 알림
│   │   ├── main/               #   메인 3탭 (급식/홈/일정)
│   │   └── sub/                #   설정, D-day, 시간표, 온보딩
│   ├── styles/                 #   테마 컬러 (라이트/다크)
│   └── widgets/                #   공용 위젯
│
├── admin-web/                  # Next.js 관리자 대시보드
│   ├── app/                    #   App Router 페이지
│   │   ├── dashboard/          #     통계 + 최근 활동
│   │   ├── posts/, comments/   #     게시글/댓글 관리
│   │   ├── reports/            #     신고 관리
│   │   ├── users/              #     사용자 관리 + 상세
│   │   └── settings/           #     앱 버전 + 공지
│   ├── components/             #   Sidebar, StatsCard, Badge
│   └── lib/                    #   Firebase, Auth, Types, Utils
│
├── functions/                  # Cloud Functions (Node.js)
├── firestore.rules             # Firestore 보안 규칙
└── admin-static/               # 레거시 관리자 (HTML/JS)
```

## 아키텍처

```
┌──────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Flutter App │────▶│   Firebase   │◀────│  Next.js Admin  │
│  (Android/   │     │              │     │  (TypeScript +  │
│   iOS)       │     │  Auth        │     │   Tailwind CSS) │
└──────┬───────┘     │  Firestore   │     └─────────────────┘
       │             │  Storage     │
       │             │  FCM         │
       ▼             └──────┬───────┘
┌─────────────┐             │
│  NEIS API   │             ▼
│  (급식,시간표 │     ┌──────────────┐
│   학사일정)   │     │ Cloud Func.  │
└─────────────┘     │ (Node.js)    │
                    │ 푸시 알림      │
                    └──────────────┘
```

## 보안

- Firestore 보안 규칙: 역할 기반 접근 제어 (`isAdmin()`, `isAdminOrManager()`)
- Firebase config 환경변수 분리 (`.env.local`, `.gitignore`)
- 입력값 길이 제한, 중복 신고 방지, HTTP 타임아웃
- Cloud Functions: 사용자 승인 상태 검증 후 알림 발송
- 글 만료 (Firestore TTL), 이미지 자동 압축 (640px)
