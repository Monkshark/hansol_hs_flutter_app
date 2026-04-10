# 한솔고등학교 앱 - 프로젝트 개요

## 프로젝트 소개

한솔고등학교 학생, 교사, 졸업생, 학부모를 위한 **풀스택 모바일 앱**이다
급식, 시간표, 학사일정 조회부터 커뮤니티 게시판, 1:1 채팅, 성적 관리까지 학교 생활 전반을 지원한다

| 항목 | 내용 |
|------|------|
| 패키지명 | `hansol_high_school` |
| 플랫폼 | Android / iOS |
| 프레임워크 | Flutter 3.x (Dart >=2.17) |
| 백엔드 | Firebase (Firestore, Auth, Storage, Functions, Messaging) |
| 관리자 도구 | Next.js 웹 대시보드 (`admin-web/`) |
| 코드 규모 | Dart 22,000+ LOC, TypeScript/JS 4,000+ LOC |

---

## 핵심 기능

### 1. 학교 정보 (NEIS API 연동)
- **급식**: 주간 조식/중식/석식 조회, 홈 위젯 표시
- **시간표**: 학년/반별 시간표, 선택과목 관리, 색상 커스터마이징
- **학사일정**: 캘린더 뷰, 개인 일정 추가, D-day 관리

### 2. 커뮤니티 게시판
- 6개 카테고리: 자유/질문/정보공유/분실물/학생회/동아리
- 글 작성 (이미지/투표/일정첨부), 댓글/대댓글, 익명 기능
- 좋아요/싫어요, 북마크, 인기글 정렬, n-gram 검색
- 신고/관리 시스템

### 3. 1:1 채팅
- 실시간 메시지, 이미지 공유
- 읽지 않은 메시지 카운트

### 4. 성적 관리 (로컬 전용)
- 내신(중간/기말), 모의고사 기록
- 수시/정시 목표 설정, 차트 시각화
- flutter_secure_storage 암호화 저장

### 5. 인증 & 권한
- 소셜 로그인 4종: Google, Apple, Kakao, GitHub
- 역할 기반 권한: admin / manager / user
- 신분 구분: 재학생 / 졸업생 / 교사 / 학부모
- 학번 검증 (5자리: 학년+반+번호)

### 6. 알림 시스템
- FCM 푸시 알림 (13종): 댓글, 대댓글, 인기글, 카테고리별 등
- 로컬 급식 알림 (조식/중식/석식 시간 설정)
- 인앱 팝업 공지, 앱 업데이트 체크

### 7. 홈 위젯 (Android/iOS)
- 오늘의 급식 위젯
- 현재 시간표 위젯

---

## 기술 스택

### Flutter / Dart
| 라이브러리 | 용도 |
|-----------|------|
| `flutter_riverpod` | 상태 관리 (AsyncNotifier/Notifier 패턴) |
| `get_it` | 의존성 주입 (DI) |
| `freezed` + `json_serializable` | 불변 데이터 모델 + JSON 직렬화 |
| `sqflite` | SQLite 로컬 DB (개인 일정) |
| `flutter_secure_storage` | 암호화 저장소 (성적, D-day 등 개인정보) |
| `shared_preferences` | 설정값, 캐시 |
| `table_calendar` | 캘린더 위젯 |
| `shimmer` | 스켈레톤 로딩 UI |
| `cached_network_image` | 이미지 캐싱 |
| `home_widget` | 홈 화면 위젯 |

### Firebase
| 서비스 | 용도 |
|--------|------|
| **Firestore** | 메인 DB (게시글, 유저, 채팅, 알림 등) |
| **Auth** | 소셜 로그인 인증 |
| **Storage** | 이미지 업로드 (프로필, 게시글, 채팅) |
| **Cloud Functions** | Kakao 커스텀 토큰, 푸시 알림 발송 |
| **Messaging (FCM)** | 푸시 알림 |
| **Crashlytics** | 크래시 리포팅 |
| **Performance** | 성능 모니터링 |
| **App Check** | API 남용 방지 |
| **Analytics** | 사용자 이벤트 추적 |

### 외부 API
| API | 용도 |
|-----|------|
| NEIS 교육정보 API | 급식, 시간표, 학사일정 |
| Kakao SDK | 카카오 로그인 |

---

## 디렉토리 구조

```
hansol_hs_flutter_app/
├── lib/                          # Flutter 앱 소스
│   ├── main.dart                 # 앱 진입점
│   ├── firebase_options.dart     # Firebase 설정 (자동생성)
│   ├── api/                      # 외부 API 연동
│   │   ├── meal_data_api.dart    #   NEIS 급식 API
│   │   ├── notice_data_api.dart  #   NEIS 학사일정 API
│   │   ├── timetable_data_api.dart # NEIS 시간표 API
│   │   ├── nies_api_keys.dart    #   NEIS API 키 (gitignore)
│   │   └── kakao_keys.dart       #   카카오 앱 키 (gitignore)
│   ├── data/                     # 데이터 레이어
│   │   ├── auth_service.dart     #   인증 서비스
│   │   ├── auth_repository.dart  #   인증 레포지토리 (DI)
│   │   ├── grade_manager.dart    #   성적 관리
│   │   ├── grade_repository.dart #   성적 레포지토리 (DI)
│   │   ├── local_database.dart   #   SQLite 일정 DB
│   │   ├── setting_data.dart     #   설정 싱글톤
│   │   ├── meal.dart             #   급식 모델 (freezed)
│   │   ├── subject.dart          #   과목 모델 (freezed)
│   │   ├── schedule_data.dart    #   일정 모델
│   │   ├── dday_manager.dart     #   D-day 관리
│   │   ├── search_tokens.dart    #   검색 토큰화 (n-gram)
│   │   ├── search_history_service.dart # 검색 기록
│   │   ├── analytics_service.dart #  Analytics 래퍼
│   │   ├── secure_storage_service.dart # 암호화 저장소
│   │   ├── service_locator.dart  #   GetIt DI 설정
│   │   ├── device.dart           #   디바이스 정보
│   │   └── subject_data_manager.dart # 선택과목 관리
│   ├── providers/                # Riverpod 상태 관리
│   │   ├── auth_provider.dart    #   인증 상태
│   │   ├── grade_provider.dart   #   성적 상태
│   │   ├── settings_provider.dart #  설정 상태
│   │   └── theme_provider.dart   #   테마 상태
│   ├── screens/                  # 화면 (UI)
│   │   ├── auth/                 #   로그인/프로필
│   │   ├── main/                 #   메인 탭 (홈/급식/일정)
│   │   ├── board/                #   게시판 (글/댓글/관리자)
│   │   ├── chat/                 #   1:1 채팅
│   │   └── sub/                  #   설정/성적/시간표/피드백 등
│   ├── widgets/                  # 재사용 위젯
│   │   ├── calendar/             #   캘린더 관련
│   │   ├── meal/                 #   급식 카드
│   │   ├── grade/                #   성적 차트
│   │   ├── home/                 #   홈 화면 위젯
│   │   ├── home_widget/          #   OS 홈 위젯
│   │   ├── setting/              #   설정 위젯
│   │   ├── skeleton.dart         #   스켈레톤 로딩
│   │   └── offline_banner.dart   #   오프라인 배너
│   ├── styles/                   # 테마/컬러
│   │   ├── app_colors.dart       #   컬러 추상 + 애니메이션
│   │   ├── light_app_colors.dart #   라이트 모드 색상
│   │   └── dark_app_colors.dart  #   다크 모드 색상
│   ├── network/                  # 네트워크
│   │   └── network_status.dart   #   연결 상태 체크
│   └── notification/             # 알림
│       ├── fcm_service.dart      #   FCM 푸시 알림
│       ├── daily_meal_notification.dart # 급식 로컬 알림
│       ├── popup_notice.dart     #   인앱 팝업 공지
│       └── update_checker.dart   #   앱 업데이트 체크
├── functions/                    # Firebase Cloud Functions (Node.js)
│   └── index.js                  #   Kakao 인증, 푸시 발송 등
├── admin-web/                    # 관리자 웹 대시보드 (Next.js)
│   ├── app/                      #   페이지 (dashboard/users/posts/...)
│   ├── components/               #   공통 컴포넌트
│   └── lib/                      #   유틸리티
├── assets/                       # 이미지/아이콘/HTML
├── android/                      # Android 네이티브
├── ios/                          # iOS 네이티브
├── test/                         # 단위/위젯/골든 테스트
├── integration_test/             # 통합 테스트
├── scripts/                      # 유틸리티 스크립트
├── firestore.rules               # Firestore 보안 규칙
├── storage.rules                 # Storage 보안 규칙
├── firestore.indexes.json        # 복합 인덱스
└── pubspec.yaml                  # 의존성 매니페스트
```

---

## 앱 초기화 흐름 (main.dart)

```
main()
  ├── Flutter 바인딩 초기화
  ├── 세로 고정 (portrait only)
  ├── Firebase 초기화
  │   ├── App Check (Play Integrity / debug)
  │   ├── Performance Monitoring
  │   ├── Analytics
  │   └── Crashlytics
  ├── Kakao SDK 초기화
  ├── SettingData 초기화 (SharedPreferences)
  ├── 알림 권한 요청
  ├── Timezone 설정 (Asia/Seoul)
  ├── 테마 모드 복원
  ├── 시간표 과목 프리로드 (2학년, 3학년)
  ├── GetIt 서비스 로케이터 설정
  ├── 급식 로컬 알림 스케줄링
  ├── FCM 초기화
  ├── 홈 위젯 초기화
  └── Riverpod ProviderScope → HansolHighSchool 앱 실행
```

## 메인 화면 구조

```
MainScreen (3탭 PageView)
  ├── Tab 0: MealScreen (급식)
  ├── Tab 1: HomeScreen (홈 대시보드) ← 기본 탭
  └── Tab 2: NoticeScreen (캘린더/일정)

postFrameCallback:
  ├── 계정 존재 확인 (삭제된 계정이면 로그아웃)
  ├── 새 학기 프로필 업데이트 체크
  ├── 온보딩 (최초 실행)
  ├── 로그인 화면 (미로그인)
  ├── Firestore 동기화 (로그인 상태)
  ├── 앱 업데이트 체크
  └── 팝업 공지 표시
```

---

## 테스트 구조

| 종류 | 파일 수 | 위치 |
|------|---------|------|
| 단위/위젯 테스트 | 15+ | `test/` |
| 골든 이미지 테스트 | 1 | `test/post_card_golden_test.dart` |
| 통합 테스트 | 1 | `integration_test/` |
| Firestore 규칙 테스트 | 34+ | (별도 프레임워크) |

### 주요 테스트 대상
- `auth_service_test.dart` - 인증 서비스
- `grade_manager_test.dart` - 성적 관리
- `grade_provider_test.dart` - Riverpod 프로바이더
- `meal_api_test.dart` - NEIS 급식 API
- `search_tokens_test.dart` - 검색 토큰화
- `secure_storage_service_test.dart` - 암호화 저장소
- `post_card_golden_test.dart` - UI 스냅샷 (골든)

---

## 개발 환경 설정

### 필수 요구사항
- Flutter SDK 3.x
- Dart SDK >=2.17
- Firebase CLI
- Android Studio 또는 VS Code
- Node.js 20 (Cloud Functions용)

### 시크릿 파일 (gitignore 대상)
```
lib/api/nies_api_keys.dart       # NEIS API 키
lib/api/kakao_keys.dart          # 카카오 앱 키
lib/firebase_options.dart        # Firebase 설정
android/app/google-services.json # Android Firebase 설정
ios/Runner/GoogleService-Info.plist # iOS Firebase 설정
admin-web/.env.local             # 관리자 웹 Firebase 키
scripts/service-account.json     # Firebase 서비스 계정
```

### 빌드 & 실행
```bash
# 의존성 설치
flutter pub get

# 코드 생성 (freezed, riverpod_generator 등)
dart run build_runner build --delete-conflicting-outputs

# 디버그 실행
flutter run

# 릴리스 빌드 (Android)
flutter build apk --release

# 테스트
flutter test
```

### Firebase 에뮬레이터
```bash
firebase emulators:start  # Firestore(8080), Auth(9099)
```
