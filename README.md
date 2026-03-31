# 한솔고등학교 앱

세종시 한솔고등학교 학생/교사를 위한 통합 학교 앱

## 주요 기능

### 급식
- NEIS API 기반 조식/중식/석식 메뉴 조회
- 주간 캘린더 날짜 선택, 월간 프리페치 캐시
- 급식 카드 탭 → 공유 / 영양정보 (알레르기 포함)
- 평일 급식 없을 시 탭하여 새로고침

### 시간표
- 1학년: 반별 시간표 자동 조회
- 2-3학년: 선택과목 기반 시간표 구성
- 과목 충돌 감지 + 해결 팝업
- 과목별 컬러 커스터마이징 (원형 컬러피커)
- 현재 교시 실시간 표시 (1분 갱신, 프로그레스 바)
- 새 학기(3월) 시간표 자동 리셋

### 일정 관리
- 월간 캘린더 (한국어, 토/일 색상 구분)
- 개인일정 CRUD (sqflite 로컬 DB)
- NEIS 학사일정 자동 표시 (6개월, 연속 중복 제거)
- D-day 관리 + 홈 화면 핀 고정

### 게시판
- 카테고리: 자유 / 질문 / 정보공유
- 공지 시스템 (최대 3개, 관리자/매니저 전용, 목록 상단 고정)
- 글 작성/수정/삭제, 댓글 + 대댓글 (들여쓰기)
- 익명 기능 (글 + 댓글, 계정 연결 유지)
- 투표 첨부 (최대 6개 선택지, 실시간 결과 바)
- 일정 공유 (날짜/시간 입력 → "내 일정에 추가" 버튼)
- 사진 첨부 (640px 자동 압축, 최대 5장, 전체화면 뷰어)
- 추천/비추천, 글 검색, 내 활동 모아보기
- 신고 기능 (사유 선택 → Firestore 저장)
- 글 자동 삭제 (1년 후 Firestore TTL)

### 알림
- 급식 알림 (조식/중식/석식, 시간 설정 가능)
- 댓글/답글 알림 (벨 아이콘 + 읽지 않은 알림 빨간 뱃지)
- 계정 알림 (가입 요청/승인/거절/삭제/정지)
- FCM + Cloud Functions 기반 푸시 알림 (Blaze 요금제 필요)

### 인증 & 권한
- Google 로그인 + 프로필 설정 (이름, 학번)
- 신분 선택: 재학생 / 졸업생 / 교사 / 학부모
- 가입 요청 → 관리자 승인 플로우
- 역할 시스템: user / manager / admin
- 매니저: 타인 글/댓글 삭제, 신고 처리, 사용자 승인, 공지 등록
- Admin: 매니저 임명/해제, 관리자 임명 (셀프 해제만 가능)
- 계정 정지 (1시간~30일, 기간 선택, 남은 시간 표시)
- 새 학기(3월) 프로필 업데이트 강제

### 설정
- 학년/반 선택 (휠 피커)
- 테마 모드 (라이트/다크/시스템)
- 급식 알림 + 게시판 알림 ON/OFF
- 캐시 크기 확인 및 삭제
- 승인/정지 상태 표시

### 기타
- 앱 업데이트 체크 (Firestore 기반, 필수/선택 업데이트)
- 첫 실행 온보딩 (4페이지 슬라이드)
- 외부 링크 (NEIS+, 리로스쿨, 한솔 공식)
- 로그인/로그아웃 시 전체 화면 새로고침
- 계정 삭제 감지 → 자동 로그아웃

## 기술 스택

| 분류 | 기술 |
|------|------|
| Frontend | Flutter (Dart) |
| Backend | Firebase (Auth, Firestore, Storage, FCM) |
| Server | Cloud Functions (Node.js) |
| API | NEIS 공공데이터 API (급식, 시간표, 학사일정) |
| Local DB | sqflite (개인일정) |
| Storage | SharedPreferences (설정, 캐시) |
| Admin | Next.js 14 + TypeScript + Tailwind CSS + Firebase SDK |

## 프로젝트 구조

```
hansol_hs_flutter_app/
├── lib/
│   ├── api/                # NEIS API 통신 (급식, 시간표, 학사일정)
│   ├── data/               # 데이터 모델, DB, Auth, 설정
│   ├── notification/       # 알림 (로컬, FCM, 업데이트 체크)
│   ├── screens/
│   │   ├── auth/           # 로그인, 프로필 설정 (신분 선택)
│   │   ├── board/          # 게시판, 글 상세, 관리자, 알림
│   │   ├── main/           # 메인 3탭 (급식/홈/일정)
│   │   └── sub/            # 설정, D-day, 시간표, 온보딩
│   ├── styles/             # 테마 컬러 (라이트/다크)
│   └── widgets/            # 공용 위젯 (급식, 캘린더, 홈, 설정)
├── admin-web/              # 관리자 웹 (Next.js)
│   ├── app/
│   │   ├── page.tsx        # 로그인 (이메일 + Google)
│   │   ├── dashboard/      # 대시보드 (통계 카드, 최근 활동)
│   │   ├── posts/          # 게시글 목록 + 상세 (댓글, 이미지, 공지)
│   │   ├── comments/       # 댓글 관리
│   │   ├── reports/        # 신고 관리
│   │   ├── users/          # 사용자 목록 + 상세 (활동 내역)
│   │   └── settings/       # 앱 버전 + 공지 관리
│   ├── components/         # Sidebar, StatsCard, Badge
│   └── lib/                # Firebase, Auth, Types, Utils
├── admin-static/           # 관리자 웹 (HTML/JS, 레거시)
├── functions/              # Cloud Functions (알림, 계정 이벤트)
├── firestore.rules         # Firestore 보안 규칙
└── assets/images/          # 이미지 에셋
```

## 관리자

### 앱 내 Admin 화면
- **신고**: 신고된 글 확인, 글 삭제 또는 무시
- **승인 대기**: 가입 요청 승인/거절
- **사용자**: Admin/매니저 상단 정렬, 역할 임명, 정지/삭제
- **정지**: 정지된 사용자 목록, 남은 기간 표시, 정지 해제

### 관리자 웹 (`admin-web/`) — Next.js 14 + TypeScript + Tailwind CSS
- **로그인**: 이메일/비밀번호 (Admin) + Google (매니저), 역할 검증
- **대시보드**: 전체 사용자/게시글/신고 수, 오늘 게시글, 최근 활동
- **게시글 관리**: 검색, 삭제, 상세 페이지 (본문/이미지/댓글/투표/공지 등록)
- **댓글 관리**: 전체 댓글 검색/삭제
- **신고 관리**: 신고 사유 확인, 글 삭제 또는 무시
- **사용자 관리**: 3탭 (승인 대기/사용자/정지), 역할 임명, 정지/해제/삭제
- **사용자 상세**: 프로필 정보, 신분, 작성 글 목록
- **설정**: 앱 버전 관리 + 공지 목록 관리 (등록/해제)

## 빌드

```bash
# 디버그
flutter run

# 릴리즈 APK 생성
flutter build apk --release

# 릴리즈 직접 설치
flutter run --release -d [기기ID]

# Cloud Functions 배포 (Blaze 필요)
firebase deploy --only functions --project [프로젝트ID]

# 관리자 웹 (개발)
cd admin-web
npm install
npm run dev
# http://localhost:3000
```
