# 한솔고등학교 앱

[![Flutter CI](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/flutter.yml/badge.svg)](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/flutter.yml)
[![Firestore Rules Tests](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/firestore-rules.yml/badge.svg)](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/firestore-rules.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/tests-305%20unit%20%2B%2034%20rules-success)
![Riverpod](https://img.shields.io/badge/state-Riverpod%202.5-00b894)
![Firebase](https://img.shields.io/badge/backend-Firebase-FFCA28?logo=firebase&logoColor=black)
[![Riverpod Graph](https://img.shields.io/badge/Riverpod%20Graph-인터랙티브-6c5ce7?logo=d3.js&logoColor=white)](https://monkshark.github.io/hansol_hs_flutter_app/riverpod_graph.html)
[![Docs](https://img.shields.io/badge/Docs-42%20문서-00b894?logo=readthedocs&logoColor=white)](https://monkshark.github.io/hansol_hs_flutter_app/)

> 세종시 한솔고등학교 학생·교사·졸업생·학부모를 위한 통합 학교 플랫폼

Flutter 기반 모바일 앱 + Next.js 관리자 대시보드로 구성된 풀스택 프로젝트입니다. NEIS 공공데이터 API 연동, Firebase 실시간 데이터베이스, 역할 기반 권한 시스템, 푸시 알림, 1:1 채팅 등 실서비스 수준의 기능을 구현했습니다.

## 스크린샷

| 온보딩 | 로그인 | 홈 | 홈 (라이트) |
|:--:|:--:|:--:|:--:|
| ![온보딩](screenshots/onboarding.png) | ![로그인](screenshots/login.png) | ![홈](screenshots/home.png) | ![홈 라이트](screenshots/home_light.png) |

| 급식 | 일정 | 일정 만들기 | 게시판 |
|:--:|:--:|:--:|:--:|
| ![급식](screenshots/meal.png) | ![일정](screenshots/calendar.png) | ![일정만들기](screenshots/schedule_create.png) | ![게시판](screenshots/board.png) |

| 게시글 상세 | 글쓰기 | 채팅 목록 | 채팅방 |
|:--:|:--:|:--:|:--:|
| ![상세](screenshots/post_detail.png) | ![글쓰기](screenshots/write_post.png) | ![채팅목록](screenshots/chat_list.png) | ![채팅방](screenshots/chat_room.png) |

|              인기글 (좋아요순)               | 검색 (최근 검색어) | 검색 결과 (n-gram) |          이미지 뷰어 (PageView + Hero)           |
|:-------------------------------------:|:--:|:--:|:-------------------------------------------:|
| ![인기글](screenshots/board_popular.png) | ![검색](screenshots/board_search.png) | ![검색결과](screenshots/board_search_results.png) | ![이미지뷰어](screenshots/post_image_viewer.gif) |

| 시간표 | 설정 | 내 계정 | 알림 설정 |
|:--:|:--:|:--:|:--:|
| ![시간표](screenshots/timetable.png) | ![설정](screenshots/settings.png) | ![내계정](screenshots/profile.png) | ![알림설정](screenshots/noti_settings.png) |

| Admin | Admin Web | Admin Web (다크) |
|:--:|:--:|:--:|
| ![Admin](screenshots/admin.png) | ![웹](screenshots/admin_web.png) | ![웹다크](screenshots/admin_web_dark.png) |

| 홈 (English) | 일정 (English) | 설정 (English) |
|:--:|:--:|:--:|
| ![홈 EN](screenshots/en_home.png) | ![일정 EN](screenshots/en_calendar.png) | ![설정 EN](screenshots/en_setting.png) |

| 위젯 (라이트/다크) | 수시 성적 관리 | 정시 성적 관리 |
|:--:|:--:|:--:|
| ![위젯 라이트](screenshots/widget_white.png) <br><br> ![위젯 다크](screenshots/widget_black.png) | ![수시](screenshots/susi.png) | ![정시](screenshots/jeongsi.png) |

## Metrics

| 지표 | 수치 | 비고 |
|------|------|------|
| **총 코드 라인** | **35,500+** | Dart 32,094 + TypeScript 1,882 + Java/XML 887 + Swift 330 + JS 485 |
| **소스 파일** | **105개** (Flutter) + **12페이지** (Admin Web) + **5개** (Android Widget) + **1개** (iOS Widget) | 26 screens, 16 추출 위젯, 50 models/utils/services + i18n 7 |
| **Cloud Functions** | **8개** | 푸시 알림, OAuth, 스케줄러, 계정 삭제 |
| **OAuth 로그인** | **4종** | Google, Apple, Kakao, GitHub |
| **푸시 알림** | **13종** | FCM 10 + 로컬 3, 카테고리별 개별 on/off |
| **테스트** | **305 + 34개** | Flutter Unit/Widget/Provider/Golden 305 + Firestore Rules emulator 34 (총 339) |
| **상태 관리** | **Riverpod 2.5** | AsyncNotifier / Notifier 기반, GetIt + Repository 패턴 DI |
| **이미지 압축** | **용량 70% 감소** | 게시글 1080px (EXIF/GPS 제거), 프로필 256px |
| **검색** | **Firestore n-gram 인덱스** | 제목+본문 2-gram array-contains-any, 350ms debounce |
| **i18n** | **한국어 + 영어** | Flutter ARB `gen-l10n`, 697 번역 키, 인앱 언어 토글 |
| **민감 데이터** | **flutter_secure_storage** | 성적은 Android Keystore / iOS Keychain 저장 |
| **API 최적화** | **호출 30회 → 1회** | 월간 프리페치 + Completer 패턴 |
| **Firestore 절감** | **읽기 30~50% 감소** | 오프라인 캐시 + limit 최적화 |
| **기술 문서** | **[42개](https://monkshark.github.io/hansol_hs_flutter_app/)** | 화면·위젯·서비스·모델별 MD 문서 + 인터랙티브 뷰어 (GitHub Pages) |
| **운영 비용** | **$0~3/월** | 1,000명 기준, 무료 한도 내 운영 가능 |

### 성능 / 사이즈 (실측)

| 항목 | 수치 | 측정 방법 |
|------|------|----------|
| **Release APK** | **72 MB** | `build/app/outputs/flutter-apk/app-release.apk` (단일 universal) |
| **Dart 라인 수** | **31,829** | `find lib -name '*.dart' \| xargs cat \| wc -l` |
| **Dart 파일 수** | **105개** | `find lib -name '*.dart' \| wc -l` |
| **Unit/Widget test 실행 시간** | **약 10초** | `flutter test` 305 tests, 로컬 머신 기준 |
| **Rules test 실행 시간** | **약 4초** | `firebase emulators:exec ... npm test` 34 tests |
| **이미지 압축 후 크기** | **원본 대비 ~30%** | 1080px 폭, JPEG quality 80, EXIF 제거 |
| **검색 fetch 상한** | **50건 / 350ms debounce** | `array-contains-any` + 클라이언트 substring 필터 |
| **게시판 페이지** | **20건 cursor pagination** | `startAfterDocument` + `limit(20)` |

## 아키텍처

```mermaid
graph TD
    subgraph Client
        A[Flutter App<br/>Android / iOS]
        B[Next.js Admin<br/>TypeScript + Tailwind]
    end

    subgraph Firebase
        C[Auth<br/>Google / Apple / Kakao / GitHub]
        D[Firestore<br/>실시간 DB]
        E[Storage<br/>이미지 / 프로필]
        F[FCM<br/>푸시 알림]
        G[Crashlytics<br/>크래시 모니터링]
    end

    subgraph Server
        H[Cloud Functions<br/>Node.js]
        I[Scheduler<br/>정지 해제 체크]
    end

    J[NEIS API<br/>급식 / 시간표 / 학사일정]

    A <-->|Riverpod 상태 관리| D
    A <--> C
    A <--> E
    A --> G
    A <-->|실시간 스트림| F
    A <-->|REST API| J

    B <-->|동일 Firestore 공유| D

    H -->|댓글 / 채팅 / 계정 이벤트| F
    H <-->|Firestore 트리거| D
    H <-->|Kakao OAuth| C
    I -->|매시간 정지 만료 체크| D
```

### Riverpod Provider 의존성 그래프

`riverpod_graph` CLI로 정적 분석 후 자동 생성. 아래는 mermaid 요약본이고, **🔗 [인터랙티브 풀버전 (GitHub Pages)](https://monkshark.github.io/hansol_hs_flutter_app/riverpod_graph.html)** 에서 D3.js 기반 zoom/drag 그래프로 모든 노드 탐색 가능.

```mermaid
graph LR
    authState[authStateProvider]
    userProfile[userProfileProvider<br/>UserProfileNotifier]
    isLoggedIn[isLoggedInProvider]
    isManager[isManagerProvider]
    isAdmin[isAdminProvider]
    isSuspended[isSuspendedProvider]
    theme[themeProvider]
    exams[examsProvider]
    examsByType[examsByTypeProvider]
    goals[goalsProvider]
    jeongsiGoals[jeongsiGoalsProvider]

    userProfile -->|watch| authState
    isLoggedIn -->|watch| authState
    isManager -->|watch| userProfile
    isAdmin -->|watch| userProfile
    isSuspended -->|watch| userProfile
    examsByType -->|watch| exams

    HansolApp[HansolHighSchool] -.watch.-> theme
    GradeScreen[GradeScreen] -.watch.-> exams
    GradeScreen -.watch.-> goals
    GradeScreen -.watch.-> jeongsiGoals

    classDef provider fill:#007acc,color:#fff,stroke:#005a9e
    classDef consumer fill:#00b894,color:#fff,stroke:#008264
    class authState,userProfile,isLoggedIn,isManager,isAdmin,isSuspended,theme,exams,examsByType,goals,jeongsiGoals provider
    class HansolApp,GradeScreen consumer
```

- `authStateProvider`를 root로 하는 인증 상태 트리: 프로필 → 권한(manager/admin/suspended) 파생
- `examsProvider` 기반으로 `examsByTypeProvider` (수시/정시 분류) 파생
- 화면(`Consumer`)은 필요한 leaf provider만 watch → 불필요한 rebuild 방지

### 데이터 흐름 (계층 모델)

```mermaid
graph LR
    User([사용자]) --> Widget[Widget / Consumer]
    Widget -->|read/watch| Provider[Riverpod Provider<br/>AsyncNotifier]
    Provider -->|호출| Manager[Manager / Repository]

    Manager -->|민감 데이터<br/>성적| Secure[(SecureStorage<br/>Keystore/Keychain)]
    Manager -->|일정·캐시| SQLite[(sqflite)]
    Manager -->|글·채팅·신고| Firestore[(Firestore)]
    Manager -->|이미지| Storage[(Cloud Storage)]

    Firestore -.트리거.-> Functions[Cloud Functions]
    Functions -->|푸시| FCM[FCM]
    FCM -.->|background| User

    classDef ui fill:#00b894,color:#fff,stroke:#008264
    classDef state fill:#007acc,color:#fff,stroke:#005a9e
    classDef store fill:#6c5ce7,color:#fff,stroke:#4834d4
    classDef server fill:#fdcb6e,color:#000,stroke:#e1b14a
    class Widget,Provider ui
    class Manager state
    class Secure,SQLite,Firestore,Storage store
    class Functions,FCM server
```

- **Widget → Provider** 만 직접 의존, Manager/저장소는 Provider 안쪽에 캡슐화
- 저장소는 데이터 민감도/접근 패턴에 따라 4가지로 분담 (아래 의사결정 일지 참조)
- 쓰기 → Firestore 트리거 → Cloud Functions → FCM 으로 비동기 푸시 흐름

## 의사결정 일지 (Architecture Decision Records)

각 결정은 *왜 다른 후보가 아니라 이 선택인가* 를 짧게 정리합니다.

<details>
<summary><b>1. 상태관리: Riverpod 2.5 (vs Provider / BLoC / GetX)</b></summary>
<br>

- **선택 이유**: 컴파일 타임 안전성(`ref.watch`), `family`/`autoDispose` 조합, AsyncNotifier로 로딩/에러 분기 코드를 줄여줌
- **버린 옵션**:
  - *Provider* — 상태가 깊어질수록 `Consumer` boilerplate 증가, AsyncValue 미지원
  - *BLoC* — Stream 기반이라 단순 CRUD에도 Event/State class 양산, 학습 곡선
  - *GetX* — DI/네비/i18n까지 한 패키지에 묶여 있어 lock-in 위험
- **트레이드오프**: `riverpod_generator` 코드 생성 의존, `ref` 객체를 비위젯 코드에 노출하지 않도록 별도 Manager 계층 유지
</details>

<details>
<summary><b>2. 민감 데이터 저장소: <a href="https://monkshark.github.io/hansol_hs_flutter_app/#data/secure_storage_service.md">flutter_secure_storage</a> (vs SharedPreferences)</b></summary>
<br>

- **대상**: 성적 (사용자 식별 가능 + 학교 맥락에서 민감)
- **선택 이유**: Android Keystore / iOS Keychain 위임으로 OS 수준 암호화. SharedPreferences는 평문 XML/plist
- **마이그레이션**: 기존 평문 데이터 → 첫 실행 시 1회 자동 이전(`migrateFromPlain`), 구 키 삭제. 회귀 방지용 unit test 8개
- **버린 옵션**: 전체 Firestore 동기화 — 성적은 *완전 로컬*이 사용자 신뢰에 더 부합
</details>

<details>
<summary><b>3. 게시판 검색: <a href="https://monkshark.github.io/hansol_hs_flutter_app/#data/search_tokens.md">클라이언트 n-gram 인덱싱</a> (vs Algolia / Typesense / 클라이언트 필터)</b></summary>
<br>

- **선택 이유**: Firestore는 LIKE/full-text 미지원. 외부 검색 인프라 추가 없이 글 저장 시 제목+본문을 2-gram으로 분해해 `searchTokens` 배열에 저장 → `array-contains-any` 쿼리. 한국어 단어 구분 모호성에도 강함
- **상한**: doc당 200 토큰 / query당 10 토큰 (Firestore array-contains-any 한계 = 30)
- **버린 옵션**:
  - *Algolia/Typesense* — 월 비용 + 인프라 추가, 학교 앱 규모엔 과도
  - *클라이언트 필터* — 페이지네이션된 20건만 검색됨 → 전체 검색 불가능
- **남은 한계**: 토큰 매칭이라 false positive 가능 → fetch 후 클라이언트 substring 1차 필터
</details>

<details>
<summary><b>4. 좋아요 카운터: Map&lt;uid,bool&gt; + 비정규화 int (vs Map only / int only)</b></summary>
<br>

- **선택 이유**: 두 표현을 동시에 보유. `likes: {uid: true}` 는 "내가 눌렀는가" O(1) 조회용, `likeCount: int` 는 인기글 정렬용 (orderBy 가능)
- **동기화**: `_toggleLike`에서 `FieldValue.increment(±1)` + Map dot-path 업데이트를 단일 트랜잭션으로 묶음. legacy 글은 `_ensureLikesMap`에서 Map size로 lazy backfill
- **rules 검증**: `validCounterDelta('likeCount')`에 `resource.data.get(field, 0)` 사용하여 기존 글 호환 + ±1 delta 강제
- **버린 옵션**:
  - *Map only* — 카운트 정렬 불가 (Firestore가 array length 기준 orderBy 불가)
  - *int only* — "내가 눌렀는가" 확인용 별도 컬렉션 필요 → 읽기 비용 ↑
</details>

<details>
<summary><b>5. 차트: CustomPainter 직접 구현 (vs fl_chart / syncfusion)</b></summary>
<br>

- **선택 이유**: 성적 추이 그래프는 등급 스케일 반전(낮을수록 좋음), 영어/한국사 절대평가 분기, 등급컷 점선, 과목별 색상 등 *비표준 요구사항*이 많음. 라이브러리 wrapper에 맞추는 것보다 Canvas로 직접 그리는 것이 간단
- **장점**: 의존성 0개, APK 사이즈 영향 0
- **트레이드오프**: 새 차트 추가 시 재사용성 낮음 → 향후 공부 통계 등에서 차트가 늘어나면 fl_chart 도입 재검토
</details>

<details>
<summary><b>6. 저장소 분담: <a href="https://monkshark.github.io/hansol_hs_flutter_app/#data/local_database.md">SQLite</a> / Firestore / <a href="https://monkshark.github.io/hansol_hs_flutter_app/#data/secure_storage_service.md">SecureStorage</a> / Cloud Storage</b></summary>
<br>

| 저장소 | 용도 | 이유 |
|---|---|---|
| **sqflite** | 개인 일정 (시간/색상/연속 일자) | Row 단위 시간 범위 쿼리 + 오프라인 우선 |
| **Firestore** | 글/댓글/채팅/신고/사용자 프로필 | 실시간 sync + 다중 클라이언트 + Cloud Functions 트리거 |
| **SecureStorage** | 성적 | OS 암호화 + 완전 로컬 |
| **Cloud Storage** | 게시글·프로필 이미지 | CDN + 직접 다운로드 URL |

각각 명확한 단일 용도 → 코드에서 "이 데이터는 어디에 있는가" 헷갈리지 않음
</details>

<details>
<summary><b>7. DI: <a href="https://monkshark.github.io/hansol_hs_flutter_app/#data/service_locator.md">GetIt + 추상 Repository</a> (vs Riverpod Provider만 / get_it 직접만)</b></summary>
<br>

- **선택 이유**: Riverpod은 위젯 트리 의존, 비위젯 코드(Manager, Cloud Functions 트리거 핸들러)에서 쓰기 어색. GetIt은 service locator로 어디서나 호출 가능
- **혼용 규칙**: 위젯 → Riverpod, Manager/Repository → GetIt. 테스트는 `setupServiceLocator()` / `resetServiceLocator()` 로 Mock 주입
- **버린 옵션**:
  - *Riverpod Provider 단독* — 비위젯 코드에서 ref 전달이 번거로움
  - *get_it 단독* — 위젯 rebuild가 자동으로 안 됨
</details>

<details>
<summary><b>8. 테스트 전략: Unit + Provider + Widget + Rules 4계층</b></summary>
<br>

- **Unit (89)**: 모델/유틸/파서. 외부 의존 0
- **Provider (17)**: `ProviderContainer`로 위젯 트리 없이 AsyncNotifier 검증
- **Widget (17)**: `ProviderScope.overrides`로 Mock notifier 주입, 로딩/에러/빈 분기
- **Firestore Rules (34)**: `@firebase/rules-unit-testing` + 에뮬레이터로 보안 규칙 자체를 검증. 코드 변경 없이 rules 회귀 방지
- **버린 옵션**: 통합 테스트 전체 의존 (Firebase Auth 실로그인) — CI 비용 ↑, 플레이크 ↑
</details>

<details>
<summary><b>9. i18n: Flutter 공식 ARB (vs easy_localization / intl_utils / GetX i18n)</b></summary>
<br>

- **선택 이유**: Flutter SDK 내장 `gen-l10n`은 빌드 타임에 타입 안전한 getter를 생성하여 오타·누락을 컴파일 단계에서 잡아줌. 추가 패키지 의존 0
- **구조**: 한국어(`app_ko.arb`) 템플릿 + 영어(`app_en.arb`), 500+ 키를 기능 프리픽스로 분류 (`login_`, `board_`, `admin_`, `data_` 등)
- **context 없는 계층 해결**: 알림·위젯 서비스는 `AppLocalizations.delegate.load(Locale('ko'))`로 BuildContext 없이 번역 접근. 데이터 모델은 `localizedDisplayName(l)` 메서드를 별도 제공하여 Firestore 저장 값(한국어)과 UI 표시 값을 분리
- **버린 옵션**:
  - *easy_localization* — JSON/CSV 지원은 편리하나 런타임 문자열 조회라 타입 안전성 없음
  - *GetX i18n* — GetX 생태계 lock-in, 상태관리까지 묶여 있어 Riverpod과 충돌
  - *intl_utils* — ARB 기반이지만 IDE 플러그인 의존, CI 환경에서 불편
</details>

## 기술 스택

| 분류 | 기술 |
|------|------|
| **Mobile** | Flutter (Dart) — Android / iOS |
| **State** | Riverpod 2.5 — AsyncNotifier / Notifier (StateNotifier 마이그레이션 완료) ([providers 문서](https://monkshark.github.io/hansol_hs_flutter_app/#providers/providers.md)) |
| **DI** | GetIt + Abstract Repository — 테스트 시 Mock 주입 가능 ([ServiceLocator 문서](https://monkshark.github.io/hansol_hs_flutter_app/#data/service_locator.md)) |
| **Admin Web** | Next.js 14 — App Router, TypeScript, Tailwind CSS |
| **Backend** | Firebase — Auth, Firestore, Storage, FCM, Crashlytics |
| **Server** | Cloud Functions (Node.js) — 푸시 알림, Kakao OAuth, 스케줄러 |
| **External API** | NEIS 공공데이터 — 급식, 시간표, 학사일정 |
| **Local** | sqflite ([일정 DB](https://monkshark.github.io/hansol_hs_flutter_app/#data/local_database.md)), SharedPreferences ([설정/캐시](https://monkshark.github.io/hansol_hs_flutter_app/#data/setting_data.md)) |
| **Auth** | Google, Apple, Kakao, GitHub OAuth ([AuthService](https://monkshark.github.io/hansol_hs_flutter_app/#data/auth_service.md), [AuthRepository](https://monkshark.github.io/hansol_hs_flutter_app/#data/auth_repository.md)) |
| **i18n** | Flutter ARB (`gen-l10n`) — 한국어(기본) + 영어, 500+ 키 |
| **CI** | GitHub Actions — analyze + test (matrix) + Codecov + Android APK 빌드 |
| **Test** | flutter_test — Unit + Widget + Provider (113 tests) |

## 주요 기능

<details>
<summary><b>급식 조회</b></summary>

- [**NEIS API**](https://monkshark.github.io/hansol_hs_flutter_app/#api/meal_data_api.md) 기반 조식/중식/석식 메뉴 실시간 조회
- **월간 프리페치** 캐시 (24시간/빈 결과 5분), Completer 패턴으로 동시 요청 방지 ([Meal 모델](https://monkshark.github.io/hansol_hs_flutter_app/#data/meal.md))
- 급식 카드 탭 → 이미지 공유, **영양 성분** (탄수화물/단백질/지방 등) + 알레르기 유발 식품 표시
- [급식 알림](https://monkshark.github.io/hansol_hs_flutter_app/#notification/daily_meal_notification.md)에 메뉴 미리보기 포함
</details>

<details>
<summary><b>시간표</b></summary>

- **1학년**: 반별 자동 조회 / **2-3학년**: [선택과목](https://monkshark.github.io/hansol_hs_flutter_app/#data/subject.md) 기반 맞춤 시간표 ([API](https://monkshark.github.io/hansol_hs_flutter_app/#api/timetable_data_api.md), [SubjectDataManager](https://monkshark.github.io/hansol_hs_flutter_app/#data/subject_data_manager.md))
- **교사 전용 시간표**: 학년 탭(1/2/3학년) → 과목 스와이프 → 중복 반 선택
- **충돌 자동 감지** + 해결 팝업, 과목별 컬러 커스터마이징 (원형 피커)
- **현재 교시** 실시간 표시 (1분 갱신, 프로그레스 바), 오늘 요일 하이라이트
- 선택과목 저장 확인 + 미저장 뒤로가기 경고
- 새 학기(3월) 시간표 + 선택과목 자동 리셋
</details>

<details>
<summary><b>일정 관리</b></summary>

- **커스텀 월간 캘린더** (스와이프 월 이동, 유동적 주 수, 한국어)
- **연속 학사일정 바** (끊김 없이 이어지는 컬러 바 + 일정명 표시)
- **개인일정** 하루/연속, **6색 + 원형 컬러피커** (밝기 조절)
- **NEIS 학사일정** 자동 표시 ([API](https://monkshark.github.io/hansol_hs_flutter_app/#api/notice_data_api.md)), 개인일정 색상 점 ([ScheduleData](https://monkshark.github.io/hansol_hs_flutter_app/#data/schedule_data.md))
- [**D-day**](https://monkshark.github.io/hansol_hs_flutter_app/#data/dday_manager.md) 관리 + 홈 화면 핀 고정
</details>

<details>
<summary><b>게시판</b></summary>

- **6개 카테고리** + **인기글** 탭: 자유 / 질문 / 정보공유 / 분실물 / 학생회 / 동아리
- **인기글 정렬**: `likeCount` 비정규화 카운터 + composite index `(likeCount desc, createdAt desc)`
- **커서 기반 페이지네이션** (20개씩, 무한 스크롤, 당겨서 새로고침)
- **공지 시스템** (최대 3개, 상단 고정, 관리자 전용)
- **댓글 + 대댓글** (들여쓰기), 글쓴이 댓글 구분 (파란 배경 + 뱃지)
- **익명 번호제**: 익명1/익명2/익명(글쓴이), Firestore Transaction
- **@멘션**: 댓글에서 `@이름` 하이라이트, 멘션 대상에게 푸시 알림, 백스페이스 시 멘션 통째 삭제
- **투표** 첨부 (최대 6선택지, 실시간 결과 바)
- **추천/비추천**: `Map<uid,bool>` + `likeCount` int counter, rules 단계 ±1 delta 검증
- **이미지 첨부**: 1080px 압축 + EXIF/GPS 제거, PageView swipe viewer + Hero animation + pinch-zoom
- [**n-gram 검색**](https://monkshark.github.io/hansol_hs_flutter_app/#data/search_tokens.md): 제목+본문 2-gram을 `searchTokens` 배열에 인덱싱, `array-contains-any` 쿼리 (350ms debounce, 50개 fetch + client substring 필터)
- [**검색 history**](https://monkshark.github.io/hansol_hs_flutter_app/#data/search_history_service.md): 최근 10개 검색어 chip, 개별/전체 삭제
- **일정 공유**, Shimmer 스켈레톤 로딩
- **바텀시트 메뉴** (아이콘 + 텍스트, 삭제/신고 빨간색 강조)
- 신고, 사용자 차단, 글 자동 삭제 (TTL), Rate Limiting
- **내 활동**: 내가 쓴 글 / 내가 쓴 댓글 / 저장한 글
</details>

<details>
<summary><b>1:1 채팅</b></summary>

- **유저 검색**으로 새 채팅 시작 (이름/학번 검색, 관리자 기본 표시) ([ChatUtils](https://monkshark.github.io/hansol_hs_flutter_app/#screens/chat/chat_utils.md))
- **실시간 메시지** (Firestore onSnapshot, limit 30)
- **읽음 표시** (per-message 카운터 기반) + 읽지 않은 메시지 수 뱃지
- **메시지 삭제**: 나만 삭제 / 같이 삭제 (안 읽었고 1시간 이내)
- **채팅방 나가기**: 시스템 메시지 + 상대방 채팅 유지
- 스켈레톤 로딩 UI
</details>

<details>
<summary><b>알림 시스템</b></summary>

- **알림 설정 화면**: 5개 카테고리별 개별 on/off
- [**급식 알림**](https://monkshark.github.io/hansol_hs_flutter_app/#notification/daily_meal_notification.md): 로컬 스케줄링 (조식/중식/석식, 시간 설정, 메뉴 미리보기)
- **인앱 알림**: 댓글/답글/계정 (벨 아이콘 + 뱃지)
- [**FCM 푸시**](https://monkshark.github.io/hansol_hs_flutter_app/#notification/fcm_service.md): 댓글, 대댓글, 새 글, 가입/승인/거절/정지/정지 해제/역할변경, 채팅
- **딥링크 라우팅**: 알림 탭 시 해당 화면으로 자동 이동 — 게시글 상세, 채팅방, 관리자 화면(가입 요청), 알림 화면(계정 승인)
- **중복 알림 방지**: 대댓글 알림을 보낸 대상에게 게시글 댓글 알림 중복 발송 스킵
- **권한 요청 바텀시트**: 온보딩 완료 후 바텀시트로 알림 허용 유도 (pre-permission 패턴), 설정에서 토글 시 권한 없으면 바텀시트 재호출 → OS 설정 이동
- **정지 만료 자동 해제**: Cloud Functions 스케줄러 (매시간)
</details>

<details>
<summary><b>건의사항</b></summary>

- **앱 건의사항 & 버그 제보** + **학생회 건의사항**
- 텍스트(1000자) + 사진 첨부(최대 3장)
- 상태 관리: 대기중 → 확인됨 → 해결됨 → 삭제 (로그 기록)
</details>

<details>
<summary><b>긴급 팝업 공지</b></summary>

- 앱 실행 시 **모달 팝업**으로 중요 공지 표시 ([PopupNotice](https://monkshark.github.io/hansol_hs_flutter_app/#notification/popup_notice.md))
- **3종 타입**: 긴급(빨강), 공지(파랑), 이벤트(초록)
- **시작/종료일** 설정 → 기간 외 자동 비활성화
- **"오늘 안 보기"** 지원 (관리자 설정으로 비활성화 가능)
- 앱 Admin 화면 + Admin Web에서 작성/관리
</details>

<details>
<summary><b>인증 & 권한</b></summary>

- **4종 OAuth**: Google / Apple / Kakao / GitHub (SVG 브랜드 로고)
- **신분 선택**: 재학생 / 졸업생 / 교사 / 학부모
- **승인 플로우**: 가입 요청 → 관리자 승인
- **3단계 역할**: user → manager → admin
- **계정 정지** (1시간~30일, 자동 해제) + **회원 탈퇴** (이중 확인, 완전 삭제)
- **프로필 사진**, 개인정보 동의, 이름 띄어쓰기 검사, 온보딩 → 로그인 플로우
</details>

<details>
<summary><b>관리자 대시보드 (Next.js)</b></summary>

- **통계 카드** + 게시글/사용자/신고 관리
- **접이식 섹션** 기반 Admin 화면 (승인 대기/정지/사용자/신고/삭제 로그/건의사항), 스크롤 중 오작동 방지
- **크래시 로그** + **건의사항 관리** (상태 변경)
- **익명 실명 확인**, 감사 로그, **다크모드**, 모바일 반응형
</details>

<details>
<summary><b>성적 관리</b></summary>

- **수시(내신)/정시(모의고사)** 탭 분리, 스와이프 전환
- **내신**: 5등급제 + 성취도(A~E) 병기, 2022 개정 교육과정 적용
- **모의고사**: 2022 개정 수능 과목 (국/수/영/한국사/통합사회/통합과학 + 제2외국어)
- **사설 모의고사** 추가 가능
- **추이 그래프**: CustomPainter 꺾은선 (등급/원점수/백분위/표준점수 모드 토글)
- **과목별 목표** 등급(수시 0.1단위) / 목표 백분위(정시) 분리 설정
- **백분위 → 등급 자동 변환** (등급컷 기준 점선 표시)
- **영어/한국사** 절대평가 과목 백분위 목표 제외
- 과목별 고정 색상, 성적 **로컬 전용 저장** (서버에 저장되지 않음) ([GradeManager](https://monkshark.github.io/hansol_hs_flutter_app/#data/grade_manager.md), [SecureStorage](https://monkshark.github.io/hansol_hs_flutter_app/#data/secure_storage_service.md))
</details>

<details>
<summary><b>홈 화면 위젯 (Android)</b></summary>

- **급식 위젯 (4×2)**: 오늘의 조식/중식/석식
- **시간표 위젯 (3×2)**: 오늘의 시간표, 현재 교시 강조
- **급식+시간표 통합 위젯 (5×2)**: 급식과 시간표를 한 화면에
- 시스템 다크/라이트 모드 자동 대응
- **자정 자동 갱신** (AlarmManager + Dart 백그라운드 콜백) ([WidgetService](https://monkshark.github.io/hansol_hs_flutter_app/#widgets/home_widget/widget_service.md))
- 앱 실행 시 자동 갱신, **Firestore 읽기 0** (캐시 데이터 활용)
</details>

<details>
<summary><b>홈 화면 위젯 (iOS)</b></summary>

- **급식 위젯 (Medium)**: 오늘의 조식/중식/석식
- **시간표 위젯 (Medium)**: 오늘의 시간표, 현재 교시 강조
- **급식+시간표 통합 위젯 (Large)**: 급식과 시간표를 한 화면에
- **SwiftUI + WidgetKit** 네이티브 구현
- App Groups를 통한 Flutter ↔ 위젯 데이터 공유
- 시스템 다크/라이트 모드 자동 대응
- 1시간 주기 Timeline 갱신
</details>

<details>
<summary><b>다국어 지원 (i18n)</b></summary>

- **Flutter 공식 ARB 기반** 국제화: `flutter_localizations` + `gen-l10n`
- **한국어 (기본)** + **영어** 2개 언어 지원, 500+ 번역 키
- **인앱 언어 전환**: 설정 화면에서 시스템/한국어/English 3택, `ValueNotifier<Locale?>` 기반 즉시 반영 (앱 재시작 불필요)
- **데이터 계층 분리**: UI 문자열은 `AppLocalizations.of(context)!`, context 없는 곳(알림·위젯 서비스)은 `AppLocalizations.delegate.load()`
- **Firestore 호환**: 카테고리 키·저장 데이터는 한국어 유지, 표시 문자열만 로컬라이즈
- **날짜 포맷 로컬라이즈**: `DateFormat`에 현재 로캘 전달하여 영어/한국어 날짜 표기 자동 전환
- **파라미터 지원**: `{name}`, `{count}` 등 동적 문자열 ARB 플레이스홀더

<!-- i18n 스크린샷 추가 예정 -->
</details>

<details>
<summary><b>새 학년 프로필 업데이트</b></summary>

- 재학생/교사만 **3월에 정보 업데이트 팝업** 표시
- 학년/반/번호 등 새 학년 정보 입력 유도
- **역할 변경 불가** (관리자만 역할 변경 가능)
</details>

<details>
<summary><b>앱 업데이트 & 오프라인</b></summary>

- [**업데이트 체커**](https://monkshark.github.io/hansol_hs_flutter_app/#notification/update_checker.md): Firestore `app_config/version`에서 최신/최소 버전 비교
  - **필수 업데이트**: 닫기 불가 다이얼로그 + 스토어 이동
  - **선택 업데이트**: "나중에" 버튼 포함 안내 다이얼로그
  - 버전 비교 로직 (`major.minor.patch`)
- [**오프라인 배너**](https://monkshark.github.io/hansol_hs_flutter_app/#network/network_status.md): 네트워크 끊기면 상단에 빨간 "오프라인 상태입니다" 표시, 재연결 시 자동 소멸
- **오프라인 캐시**: 급식/시간표는 로컬 캐시로 오프라인에서도 조회 가능
</details>

## 보안 & 개인정보 보호

- **Firestore 규칙**: 역할 기반 접근 제어, 필드 단위 update 검증
- **채팅 메시지 보안**: 참여자만 읽기/쓰기 가능, 메시지 업데이트 권한 제어 (삭제 기능용)
- **게시글 필드 단위 보호**: 비작성자는 좋아요/투표/북마크 필드만 수정 가능
- **Rate Limiting**: 글 30초, 댓글 10초 쿨타임
- **Cloud Functions**: 승인 상태 + 알림 설정 체크 후 발송
- **감사 로그**: 모든 관리 행위 + 게시글 삭제 이력 기록
- **크래시 모니터링**: Crashlytics + Firestore 기록
- **데이터 보호**: 이미지 압축, TTL 만료, 사용자 차단, 개인정보 동의
- **OAuth 전용 인증**: 비밀번호를 저장하지 않는 소셜 로그인 체계
- **회원 탈퇴 시 즉시 파기**: Firestore 문서 → Auth 계정 순서로 삭제하여 권한 오류 방지, 이름/프로필 사진/하위 컬렉션 완전 삭제
- **개인정보 처리방침**: 앱 내 표시, 가입 시 동의 필수

## 테스트 & CI/CD

| 구분 | 내용 |
|------|------|
| **Unit Test** | 모델 직렬화, 등급 변환, 급식 파싱, 시간표 교시 계산, 검색 토크나이저, 검색 기록(SharedPreferences), secure_storage 마이그레이션, 버전 비교, FCM 페이로드, 채팅 ID 생성, 위젯 서비스 로직 등 (258개) |
| **Provider Test** | `ProviderContainer`로 위젯 트리 없이 AsyncNotifier 직접 검증 (17개) |
| **Widget Test** | `ProviderScope.overrides` + Mock Notifier 주입 — 로딩/에러/빈 상태 분기 검증 (17개) |
| **Golden Test** | PostCard 5종 변종(기본/좋아요/공지/+N badge/익명+매니저뷰) PNG 스냅샷 비교, `fake_cloud_firestore`로 mock 주입 (5개) |
| **Repository Test** | GetIt 기반 Mock 주입 패턴 데모 (8개) |
| **Firestore Rules Test** | `@firebase/rules-unit-testing` + 에뮬레이터로 보안 규칙 단위 테스트 (34개) — 권한/카운터 delta/필드 위조 검증 |
| **합계** | **305 + 34 = 339개**, 전체 통과 |
| **CI** | GitHub Actions matrix — analyze + test 병렬 실행, Codecov 커버리지 업로드, master push 시 Android APK 빌드. Rules 테스트는 별도 워크플로우(Firebase 에뮬레이터) |
| **정적 분석** | `--no-fatal-infos --no-fatal-warnings` 레벨로 코드 품질 관리 |
| **더미 데이터** | Node.js 스크립트로 Firestore 더미 데이터 삽입/삭제 자동화 |

## 데이터 모델

```mermaid
erDiagram
    users ||--o{ posts : "작성"
    users ||--o{ notifications : "수신"
    users ||--o{ subjects : "선택과목"
    posts ||--o{ comments : "포함"
    posts ||--o{ reports : "신고"
    chats ||--o{ messages : "포함"
    users }o--o{ chats : "참여"

    users {
        string uid PK
        string name
        string studentId
        string role
        string userType
        boolean approved
        timestamp suspendedUntil
        string profilePhotoUrl
        string fcmToken
        boolean notiComment
        boolean notiChat
    }

    posts {
        string id PK
        string title
        string content
        string category
        string authorUid FK
        boolean isAnonymous
        boolean isPinned
        int likes
        int dislikes
        array bookmarkedBy
        array pollOptions
        map pollVotes
    }

    comments {
        string id PK
        string authorUid FK
        string content
        boolean isAnonymous
        string parentId
        timestamp createdAt
    }

    chats {
        string id PK
        array participants
        map participantNames
        string lastMessage
        map unreadCount
    }

    messages {
        string id PK
        string senderUid FK
        string content
        boolean deleted
        array deletedFor
    }
```

## Technical Challenges & Solutions

<details>
<summary><b>Firebase Auth 토큰 동기화 문제 (Permission Denied)</b></summary>
<br>

**문제:** 소셜 로그인 직후 Firestore 문서 조회 시 PERMISSION_DENIED 발생 — Auth 토큰이 Firestore SDK에 전파되기 전에 요청이 나감

**해결:** `getIdToken(true)`로 토큰 강제 갱신 + 최대 3회 재시도 로직으로 첫 설치/재로그인 시에도 안정적으로 프로필 확인
</details>

<details>
<summary><b>급식 API 동시 요청 경합 (Race Condition)</b></summary>
<br>

**문제:** 여러 화면에서 동시에 같은 월의 급식 데이터를 요청하면 중복 API 호출 발생

**해결:** [`Completer` 패턴](https://monkshark.github.io/hansol_hs_flutter_app/#api/meal_data_api.md)으로 동일 월 프리페치를 단일 Future로 병합, 진행 중인 요청이 있으면 기존 Future를 공유
</details>

<details>
<summary><b>익명 게시판 번호 일관성 (Concurrent Write)</b></summary>
<br>

**문제:** 클라이언트에서 익명 번호를 부여하면 동시 댓글 시 같은 번호가 중복 할당될 수 있음

**해결:** Firestore Transaction으로 게시글 문서의 `anonymousMap`을 원자적으로 읽기/쓰기하여 번호 중복 방지
</details>

<details>
<summary><b>선택과목 시간표 충돌 (Slot Conflict)</b></summary>
<br>

**문제:** 2-3학년 선택과목 조합 시 같은 교시에 다른 반의 수업이 겹칠 수 있음

**해결:** 시간표 빌드 시 슬롯별 충돌 자동 감지 → 사용자에게 선택 다이얼로그 표시, 선택 결과를 로컬에 저장하여 재충돌 방지
</details>

<details>
<summary><b>Firestore 보안 규칙과 기능 충돌 (Field-level Validation)</b></summary>
<br>

**문제:** 게시글 update를 `작성자만` 허용하면 다른 유저의 투표/추천이 차단됨

**해결:** `request.resource.data.diff(resource.data).affectedKeys().hasOnly([...])` 로 필드 단위 검증 — 인터랙션 필드만 변경 시 모든 인증 유저 허용
</details>

<details>
<summary><b>채팅 읽음 확인 실시간 동기화 (Dual Stream)</b></summary>
<br>

**문제:** 메시지 스트림과 별도로 읽음 상태를 추적하면 추가 Firestore 읽기 발생

**해결:** 채팅방 문서의 `unreadCount` 맵을 별도 `StreamBuilder`로 감시하여 단일 문서 스트림으로 읽음 상태 실시간 반영
</details>

<details>
<summary><b>Cloud Functions 알림 설정 개별 제어 (Server-side Filtering)</b></summary>
<br>

**문제:** FCM 푸시는 서버에서 발송하므로 클라이언트에서 카테고리별 on/off 불가

**해결:** Firestore `users/{uid}`에 `notiComment`, `notiReply`, `notiChat` 등 필드 저장, Cloud Functions에서 발송 전 해당 필드 체크하여 `false`면 발송 스킵
</details>

<details>
<summary><b>정지 만료 자동 해제 (Scheduler Trigger)</b></summary>
<br>

**문제:** 계정 정지 만료 시간이 지나도 Firestore 필드가 자동으로 삭제되지 않아 `onUserUpdated` 트리거 불발

**해결:** Cloud Functions Scheduler로 매시간 `suspendedUntil <= now`인 유저를 조회하여 필드 삭제 → `onUserUpdated` 트리거 → 정지 해제 푸시 발송
</details>

<details>
<summary><b>관리자 화면 Firestore 읽기 과다 (Stream → Future 전환)</b></summary>
<br>

**문제:** 관리자 화면이 `StreamBuilder`로 유저/신고/로그를 실시간 감시하여, 화면 열기만 해도 130+ 읽기 발생. 데이터 변경 시마다 전체 재조회

**해결:** `StreamBuilder` → `FutureBuilder`로 전환하여 열 때 1회만 조회 + 액션(승인/삭제 등) 후 `_refresh()`로 수동 갱신. `ExpansionTile`을 펼칠 때만 child를 렌더링하여 접힌 탭은 읽기 0. 결과: **130 → 20~30 읽기로 감소**
</details>

<details>
<summary><b>계정 삭제 순서 문제 (Auth → Firestore 권한 소실)</b></summary>
<br>

**문제:** `user.delete()` 호출 시 Firebase Auth가 즉시 로그아웃되어, 이후 Firestore 문서 삭제가 PERMISSION_DENIED로 실패

**해결:** Firestore 문서를 먼저 삭제(인증 상태 유지 중)한 후 Auth 계정 삭제. `uid`를 미리 변수에 저장하여 삭제 순서 역전에 의한 참조 소실 방지
</details>

<details>
<summary><b>Riverpod AsyncNotifier 경합 상태 (invalidateSelf Race Condition)</b></summary>
<br>

**문제:** `ExamsNotifier`의 `add()` / `delete()` 같은 mutator에서 `ref.invalidateSelf()`로 재조회를 트리거했더니, Provider 단위 테스트가 간헐적으로 실패. invalidate가 비동기로 처리되어 다음 `read()`가 *이전* state를 반환하는 race condition

**해결:** mutator 내부에서 `final current = await future;` 로 현재 state를 먼저 확보 → 저장소 갱신 → `state = AsyncData([...current, exam])` 로 직접 state 교체. invalidateSelf를 제거하여 race condition 원천 차단. 동일 패턴을 `GoalsNotifier` / `JeongsiGoalsNotifier`에도 적용
</details>

<details>
<summary><b>위젯 테스트의 비결정적 Timer Leak</b></summary>
<br>

**문제:** `_LoadingExamsNotifier` mock에서 `await Future.delayed(Duration(seconds: 30))`로 영구 로딩을 시뮬레이션했더니 `flutter test`가 "A Timer is still pending even after the widget tree was disposed" 로 실패

**해결:** `Completer<List<Exam>>` 패턴으로 교체 — Future를 외부 신호로 완료시킬 수 있도록 하여 테스트 종료 시점에 명시적으로 `complete()` 호출. Provider 테스트에서도 `addTearDown(container.dispose)`로 ProviderContainer 누수 방지
</details>

<details>
<summary><b>StatefulWidget 1,400+ 라인 → Stateless Composition (Refactoring)</b></summary>
<br>

**문제:** `post_detail_screen.dart`(1442줄), `admin_screen.dart`(1071줄), `write_post_screen.dart`(1119줄), `timetable_view_screen.dart`(943줄) 4개 화면이 모든 sub-widget을 private 클래스 / `_buildXxx` 메서드로 한 파일에 가지고 있어 가독성/재사용성/테스트성이 모두 저하. 단순 string match로 재사용 위치를 찾기도 어려움

**해결:** 두 가지 패턴으로 분리
1. **Private class → Public StatelessWidget 추출** — `post_detail_screen` 의 `_PollCard` / `_VoteButton` / `_CommentItem` / `_EventAttachCard`, `admin_screen` 의 5개 탭 클래스, `timetable_view` 의 다이얼로그/Painter 등을 별도 파일로 이동 + `_` prefix 제거
2. **State 의존 builder method → Callback parameter 위젯** — `write_post_screen` 의 `_buildEventForm` / `_buildPollForm` / `_buildImageSection` 은 state를 직접 참조하므로, state 값과 setState wrapper를 명시적 callback (`onPickDate`, `onAddOption`, `onReorder`...)으로 받는 StatelessWidget으로 변환

**결과:** 4개 화면 합계 4,575 → 2,589줄 (-43%), 15개 위젯 모듈로 분리, 113개 테스트 모두 통과 (회귀 0)
</details>

<details>
<summary><b>Repository 패턴 + GetIt 점진적 마이그레이션</b></summary>
<br>

**문제:** [`AuthService`](https://monkshark.github.io/hansol_hs_flutter_app/#data/auth_service.md)/[`GradeManager`](https://monkshark.github.io/hansol_hs_flutter_app/#data/grade_manager.md)가 static 메서드로 25개 이상의 호출 사이트에 흩어져 있어 한번에 DI로 전환하면 전 파일 수정 필요 + 회귀 위험

**해결:** Abstract [`AuthRepository`](https://monkshark.github.io/hansol_hs_flutter_app/#data/auth_repository.md) / [`GradeRepository`](https://monkshark.github.io/hansol_hs_flutter_app/#data/grade_repository.md) 인터페이스를 새로 정의하고 `FirebaseAuthRepository` / `LocalGradeRepository` 가 기존 static 메서드를 위임 호출. 신규 코드는 `GetIt.I<AuthRepository>()`로 가져가고 기존 호출 사이트는 그대로 둠. 테스트에서는 `setupServiceLocator()` / `resetServiceLocator()` + Mock 구현체로 주입 가능 → 점진적 마이그레이션과 백워드 호환을 동시에 확보
</details>

<details>
<summary><b>i18n Context-less 계층 번역 (Notification · Widget Service)</b></summary>
<br>

**문제:** 로컬 알림([`DailyMealNotification`](https://monkshark.github.io/hansol_hs_flutter_app/#notification/daily_meal_notification.md))과 홈 위젯 서비스([`WidgetService`](https://monkshark.github.io/hansol_hs_flutter_app/#widgets/home_widget/widget_service.md))는 `BuildContext` 없이 실행되어 `AppLocalizations.of(context)` 사용 불가. 데이터 모델(`Meal.getMealType`, `Exam.displayName`)의 반환값은 Firestore 저장과 UI 표시에 동시 사용되어 단순 교체 불가

**해결:** 3가지 패턴 적용
1. **delegate.load()**: 알림·위젯 서비스에서 `AppLocalizations.delegate.load(Locale('ko'))`로 context 없이 번역 객체 획득
2. **key 반환 + UI 번역**: `getMealType()` → `getMealTypeKey()` (key 문자열 반환), UI 계층에서 `meal_breakfast`/`meal_lunch`/`meal_dinner` ARB 키로 변환
3. **dual getter**: `displayName` (한국어, Firestore 저장용) + `localizedDisplayName(l)` (UI 표시용) 분리하여 기존 데이터 호환성 유지
</details>

<details>
<summary><b>채팅 읽음 표시 전체 소실 (Global Counter Bug)</b></summary>
<br>

**문제:** 새 메시지를 전송하면 상대방의 `unreadCount`가 1로 증가하면서, 글로벌 `otherUnread == 0` 조건으로 읽음을 판정하던 기존 로직이 모든 메시지의 "읽음" 표시를 일괄 제거

**해결:** 글로벌 비교 대신 per-message 카운터(`myUnreadRemaining`) 도입. `otherUnread` 값으로 초기화 후 최신 메시지부터 역순 순회하며 1씩 차감 — 카운터가 0이 된 이후의 메시지만 "읽음" 표시. 기존 단일 문서 스트림 구조를 유지하면서 정확한 per-message 읽음 판정 달성
</details>

<details>
<summary><b>홈 위젯 데이터 동기화 (Flutter ↔ Native)</b></summary>
<br>

**문제:** Android 위젯(Java)은 Dart 코드를 직접 실행할 수 없어 NEIS API 데이터를 위젯에 전달할 방법이 필요

**해결:** `home_widget` 패키지로 Dart → SharedPreferences → Java 브릿지 구성. 시간표는 앱 내 `timetable_view_screen`에서 완성된 그리드를 저장하고 위젯이 읽기만 수행. 자정 갱신은 `AlarmManager` → `HomeWidgetBackgroundIntent`로 Dart 엔진을 백그라운드 실행하여 API 직접 호출
</details>


