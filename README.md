# 한솔고등학교 앱

세종시 한솔고등학교 학생/교사를 위한 통합 학교 앱

## 기능

### 급식
- 조식/중식/석식 메뉴 조회 (NEIS API)
- 주간 캘린더 날짜 선택
- 급식 카드 탭 → 공유, 영양정보 (알레르기 포함)
- 월간 프리페치 캐시, 탭하여 새로고침

### 시간표
- 1학년: 반별 시간표 (NEIS API)
- 2-3학년: 선택과목 기반 시간표
- 과목 충돌 감지 + 해결 팝업
- 과목별 컬러 커스터마이징 (원형 컬러피커)
- 현재 교시 실시간 표시 (1분 갱신)

### 일정 관리
- 월간 캘린더 (한국어)
- 개인일정 CRUD (sqflite DB)
- 학사일정 자동 표시 (NEIS API)
- D-day 관리 + 홈 화면 핀

### 게시판
- 카테고리: 자유 / 질문 / 정보공유
- 글 작성/수정/삭제, 댓글
- 익명 기능 (글 + 댓글)
- 투표 첨부 (최대 6개 선택지, 결과 바)
- 일정 공유 ("내 일정에 추가" 버튼)
- 사진 첨부 (640px 자동 압축, 최대 5장)
- 추천/비추천
- 글 검색, 내 활동 모아보기
- 신고 기능

### 알림
- 급식 알림 (조식/중식/석식, 시간 설정 가능)
- 게시판 알림 (FCM 토픽 구독)
- Cloud Functions: 댓글 → 글 작성자 푸시

### 설정
- Google 로그인 + 프로필 (이름, 학번)
- 학년/반 선택
- 테마 모드 (라이트/다크/시스템)
- 알림 ON/OFF + 시간 설정
- 캐시 삭제

### 기타
- 앱 업데이트 체크 (Firestore 기반)
- 첫 실행 온보딩 (4페이지 슬라이드)
- 외부 링크 (NEIS+, 리로스쿨, 한솔 공식)

## 기술 스택

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Auth, Firestore, Storage, FCM, Cloud Functions)
- **API**: NEIS 공공데이터 API (급식, 시간표, 학사일정)
- **Local DB**: sqflite (개인일정), SharedPreferences (설정/캐시)
- **Admin**: HTML/JS + Firebase SDK (관리자 웹)

## 프로젝트 구조

```
├── lib/
│   ├── api/              # NEIS API 통신
│   ├── data/             # 데이터 모델, DB, Auth
│   ├── notification/     # 알림 (로컬, FCM)
│   ├── screens/          # 화면
│   │   ├── auth/         # 로그인, 프로필 설정
│   │   ├── board/        # 게시판
│   │   ├── main/         # 메인 3탭 (급식/홈/일정)
│   │   └── sub/          # 서브 화면
│   ├── styles/           # 테마 컬러
│   └── widgets/          # 공용 위젯
├── admin-web/            # 관리자 웹 (HTML/JS)
├── functions/            # Cloud Functions (Node.js)
└── assets/images/        # 이미지 에셋
```

## 관리자 웹

`admin-web/` 폴더에 별도 관리자 페이지 포함:
- 대시보드 (통계)
- 게시글 관리 (검색, 삭제)
- 신고 관리 (처리, 무시)
- 사용자 목록
- 앱 버전 설정 (업데이트 알림 제어)

## 설정 방법

1. Firebase 프로젝트 생성 후 `google-services.json` 배치
2. `lib/api/nies_api_keys.dart`에 NEIS API 키 설정
3. `lib/firebase_options.dart` 생성 (FlutterFire CLI)
4. `admin-web/js/firebase-init.js`에 Firebase config 설정
5. Firestore 보안 규칙 + 복합 인덱스 설정
6. Cloud Functions 배포: `firebase deploy --only functions`
