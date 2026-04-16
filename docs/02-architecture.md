# 아키텍처 & 설계 패턴

## 전체 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌──────────────┐  │
│  │Screens │  │Widgets │  │Styles  │  │ Notification  │  │
│  │(auth/  │  │(calendar│  │(colors)│  │ (FCM/local/  │  │
│  │ board/ │  │ meal/   │  │        │  │  popup/update)│  │
│  │ chat/  │  │ grade/  │  │        │  │              │  │
│  │ main/  │  │ home/   │  │        │  │              │  │
│  │ sub/)  │  │ setting)│  │        │  │              │  │
│  └───┬────┘  └───┬────┘  └────────┘  └──────────────┘  │
│      │           │                                       │
├──────┼───────────┼───────────────────────────────────────┤
│      │    State Management Layer                         │
│  ┌───┴───────────┴────────────────────────────────────┐  │
│  │  Riverpod Providers (auth/grade/settings/theme/     │  │
│  │  locale/appRefresh) + global ProviderContainer     │  │
│  └───┬────────────────────────────────────────────────┘  │
│      │                                                   │
├──────┼───────────────────────────────────────────────────┤
│      │    Data Layer                                     │
│  ┌───┴────────────────────────────────────────────────┐  │
│  │  Repositories (AuthRepository, GradeRepository)    │  │
│  │  Services (AuthService, AnalyticsService, ...)     │  │
│  │  Managers (GradeManager, DDayManager, ...)         │  │
│  │  Models (UserProfile, Meal, Subject, Exam, ...)    │  │
│  └───┬────────────────────────────────────────────────┘  │
│      │                                                   │
├──────┼───────────────────────────────────────────────────┤
│      │    Infrastructure Layer                           │
│  ┌───┴────────────────────────────────────────────────┐  │
│  │  Firebase (Firestore/Auth/Storage/Functions/FCM)   │  │
│  │  SQLite (sqflite) · SecureStorage · SharedPrefs    │  │
│  │  NEIS API (HTTP) · Kakao SDK                       │  │
│  └────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 상태 관리 전략

이 프로젝트는 **Riverpod 2.5**를 핵심 상태 관리 도구로 사용. 글로벌 `ProviderContainer`로 비위젯 코드에서도 provider 접근 가능

### 1. Riverpod AsyncNotifier / Notifier

가장 권장되는 패턴. 비동기 데이터를 `AsyncValue<T>`로 래핑해 로딩/에러/데이터 상태를 자동 관리함

```dart
// providers/grade_provider.dart
class ExamsNotifier extends AsyncNotifier<List<Exam>> {
  @override
  Future<List<Exam>> build() async {
    return GradeManager.loadExams();  // 초기 로드
  }

  Future<void> add(Exam exam) async {
    await GradeManager.addExam(exam);
    state = AsyncData(await GradeManager.loadExams());  // 상태 갱신
  }
}
```

**사용처**: 성적 관리 (`examsProvider`, `goalsProvider`), 인증 상태 (`userProfileProvider`), 테마 (`themeProvider`)

### 2. StreamProvider

Firebase 실시간 데이터에 사용함

```dart
// providers/auth_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

### 3. 파생 Provider

다른 Provider에서 계산된 값을 도출함

```dart
final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.isManager ?? false;
});
```

### 4. StreamBuilder (위젯 내 직접 사용)

Firestore 실시간 스트림은 대부분 위젯에서 직접 `StreamBuilder`로 소비함
게시글 목록, 댓글, 채팅 메시지, 알림 등이 이 패턴임

```dart
// board/post_detail_screen.dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance.doc('posts/$postId').snapshots(),
  builder: (context, snapshot) { ... },
)
```

### 5. FutureBuilder

1회성 비동기 데이터 로드에 사용함

```dart
// meal_screen.dart
FutureBuilder<Meal?>(
  future: MealDataApi.getMeal(date: selectedDate, mealType: 2),
  builder: (context, snapshot) { ... },
)
```

### 6. 비위젯 코드에서 Riverpod 접근

`main.dart`에서 `ProviderContainer`를 전역으로 노출하여, 위젯 트리 밖 코드에서도 provider 접근 가능:

```dart
// main.dart
late final ProviderContainer providerContainer;

// 비위젯 코드 (login_screen, setting_screen 등)
providerContainer.read(appRefreshProvider.notifier).refresh();
providerContainer.read(localeProvider.notifier).setLocale(Locale('en'));
```

`UncontrolledProviderScope(container: providerContainer)`로 위젯 트리와 동일 컨테이너 공유

### 상태 관리 사용 가이드

| 데이터 유형 | 패턴 | 예시 |
|------------|------|------|
| 앱 전역 상태 | Riverpod Notifier/AsyncNotifier | 테마, 인증, 성적, 언어, 알림설정 |
| Firebase 실시간 데이터 | StreamBuilder | 게시글, 댓글, 채팅 |
| 1회성 API 호출 | FutureBuilder | 급식, 시간표 |
| 화면 로컬 상태 | setState | 입력 폼, 탭 인덱스 |
| 전역 이벤트 | Riverpod + StreamController | 앱 리프레시 (appRefreshProvider), 알림 딥링크 (notificationStream) |

---

## 의존성 주입 (DI)

### GetIt 서비스 로케이터

`service_locator.dart`에서 앱 시작 시 싱글톤 서비스를 등록함

```dart
Future<void> setupServiceLocator() async {
  GetIt.I.registerSingleton<AuthRepository>(FirebaseAuthRepository());
  GetIt.I.registerLazySingleton<GradeRepository>(() => LocalGradeRepository());
  
  final db = LocalDataBase();
  await db.migrateFromPrefs();
  GetIt.I.registerSingleton<LocalDataBase>(db);
}
```

**등록된 서비스** (GetIt):
- [`AuthRepository`](data/auth_repository.md) → [`FirebaseAuthRepository`](data/auth_repository.md) (싱글톤)
- [`GradeRepository`](data/grade_repository.md) → [`LocalGradeRepository`](data/grade_repository.md) (레이지 싱글톤)
- [`LocalDataBase`](data/local_database.md) (싱글톤, 마이그레이션 후 등록)

**별도 싱글톤** (GetIt 미사용):
- [`PostRepository`](data/post_repository.md) — `PostRepository.instance`로 접근. 게시판 전용이라 전역 DI 불필요

### Repository 패턴

```
AuthService (static 메서드)
    ↑
AuthRepository (abstract)    ← 테스트에서 mock 가능
    ↑
FirebaseAuthRepository       ← 실제 구현체
    ↑
GetIt.I<AuthRepository>()    ← 어디서든 접근
```

**장점**: 테스트 시 `AuthRepository`를 mock으로 교체 가능

---

## 네비게이션 구조

### 메인 네비게이션 (3탭)

```
MainScreen
  └── PageView (스와이프 전환)
      ├── [0] MealScreen      (급식)
      ├── [1] HomeScreen       (홈 대시보드) ← 기본
      └── [2] NoticeScreen     (캘린더/일정)
```

### 화면 전환 흐름

```
HomeScreen
  ├── → AdminScreen (관리자만)
  │     └── TabBar: 가입대기 / 정지유저 / 승인유저 / 신고 / 삭제로그 / 팝업 / 피드백
  ├── → NotificationScreen (알림)
  ├── → SettingScreen (설정)
  │     ├── → ProfileEditScreen (프로필 수정)
  │     ├── → TimetableSelectScreen → TimetableViewScreen
  │     ├── → GradeScreen → GradeInputScreen
  │     ├── → NotificationSettingScreen
  │     └── → FeedbackScreen
  ├── → BoardScreen (게시판)
  │     ├── → PostDetailScreen (글 상세)
  │     │     └── → WritePostScreen (수정)
  │     ├── → WritePostScreen (새 글)
  │     ├── → MyPostsScreen (내 활동)
  │     └── → BookmarkedPostsScreen (북마크)
  ├── → ChatListScreen (채팅 목록)
  │     └── → ChatRoomScreen (채팅방)
  ├── → DDayScreen (D-day)
  └── → GradeScreen (성적)

LoginScreen (미로그인 시)
  └── → ProfileSetupScreen (최초 가입)
```

### 딥링크 (FCM 알림 탭)

```
FCM 알림 탭
  ├── type=comment/new_post → PostDetailScreen
  ├── type=chat → ChatRoomScreen
  └── type=account → 무시 (앱 열기만)
```

`rootNavigatorKey`를 사용해 어디서든 네비게이션 가능:
```dart
rootNavigatorKey.currentState?.push(
  MaterialPageRoute(builder: (_) => PostDetailScreen(postId: postId)),
);
```

---

## 태블릿 가로 대응

폰은 세로 잠금, 태블릿(shortestSide >= 600dp)만 가로 모드를 허용함

### 전략

```
main() → SystemChrome.setPreferredOrientations([portraitUp, portraitDown])
  └── HansolHighSchool.initState() → 태블릿이면 landscape 추가 허용

MaterialApp.builder → 가로 모드 시 콘텐츠 폭 제한
  ├── 세로: maxWidth = 화면 폭 (제한 없음)
  └── 가로: maxWidth = 화면 높이 × 9/16 (폰 비율 유지)
```

`MaterialApp.builder`에서 전체 Navigator를 감싸므로 모든 라우트(메인, 서브 화면, 다이얼로그)에 일괄 적용됨

---

## 테마 시스템

### 컬러 아키텍처

```
AppColors (abstract)
  ├── LightAppColors (싱글톤) - 라이트 모드 색상
  ├── DarkAppColors (싱글톤) - 다크 모드 색상
  └── AnimatedAppColors (싱글톤) - 색상 보간(lerp) 애니메이션
```

[`AnimatedAppColors`](styles/app_colors.md)는 라이트/다크 색상 사이를 0.0~1.0 progress로 보간함:

```dart
AppColors.theme.primaryColor    // 현재 테마의 primary 색상
AppColors.theme.mealCardColor   // 급식 카드 배경색
```

### 테마 모드 관리

```
SettingData.themeModeIndex (SharedPreferences)
         │
         └── themeProvider (Riverpod, keepAlive)
                │
                └── HansolHighSchool.build()
                      → AnimatedAppColors.setDark() → 컬러 보간
```

---

## 데이터 저장 전략

| 데이터 | 저장소 | 이유 |
|--------|--------|------|
| 게시글/댓글/채팅 | Firestore | 실시간 동기화 필요 |
| 유저 프로필/권한 | Firestore | 서버 권한 검증 필요 |
| 성적/목표/D-day | flutter_secure_storage | 개인정보 → 암호화 |
| 개인 일정 | SQLite (sqflite) | 복잡한 쿼리, Firestore 동기화 |
| 앱 설정 | SharedPreferences | 단순 key-value |
| 검색 기록 | SharedPreferences | 로컬 전용, 비민감 |
| 시간표 캐시 | SharedPreferences | API 응답 캐싱 |
| 이미지 | Firebase Storage | 서버 공유 필요 |
| FCM 토큰 | Firestore (user doc) | 서버에서 푸시 발송 시 필요 |

### 데이터 동기화 패턴

여러 데이터는 **로컬 우선 + Firestore 백업** 전략을 사용함:

```
앱 시작
  ├── 로컬에서 읽기 (빠른 표시)
  └── Firestore에서 동기화 (최신화)

데이터 저장
  ├── 로컬에 저장 (즉시)
  └── Firestore에 동기화 (백그라운드)
```

적용 대상: 개인 일정 (`LocalDataBase`), D-day ([`DDayManager`](data/dday_manager.md)), 선택과목 ([`SubjectDataManager`](data/subject_data_manager.md))

---

## 코드 생성

### Freezed 모델

불변(immutable) 데이터 클래스를 자동 생성함:

```dart
// data/meal.dart
@freezed
class Meal with _$Meal {
  const factory Meal({
    String? meal,
    required DateTime date,
    required int mealType,
    required String kcal,
    @Default('') String ntrInfo,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}
```

`build_runner`가 `meal.freezed.dart` + `meal.g.dart`를 생성함

### Riverpod Generator

`@Riverpod` 어노테이션으로 Provider를 자동 생성함:

```dart
// providers/theme_provider.dart
@Riverpod(keepAlive: true)
class Theme extends _$Theme {
  @override
  ThemeMode build() { ... }
}
```

→ `theme_provider.g.dart`에 `themeProvider` 자동 생성

### 코드 생성 실행

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 에러 처리 전략

### 크래시 리포팅

```
Flutter 에러 발생
  ├── Firebase Crashlytics 전송 (자동)
  └── Firestore crash_logs 컬렉션 기록 (커스텀)
      └── error, stack, library, uid, createdAt
```

### 네트워크 에러 & 오프라인 퍼스트

- [`NetworkStatus`](network/network_status.md): `isUnconnected()`(일회성) + `onStatusChange`(실시간 스트림) 제공
- `OfflineBanner`: 네트워크 상태 + 동기화 상태(대기 수, 동기화 중) 표시
- [`OfflineQueueManager`](network/offline_queue_manager.md): 오프라인 시 글/댓글 작성을 sqflite 큐에 저장, 네트워크 복원 시 자동 replay (최대 3회 재시도)
- [`PostRepository`](data/post_repository.md): `createPost`, `addComment`에 오프라인 감지 → 큐 저장 분기
- 각 API 호출은 try/catch로 감싸고, 실패 시 빈 데이터 또는 캐시 반환

### Firebase 초기화 실패

main.dart에서 Firebase 초기화를 try/catch로 감싸 앱 자체는 항상 실행되도록 함

### catch 블록 로깅 원칙

모든 `catch` 블록은 `dart:developer`의 `log()`로 에러 메시지를 기록함. `catch (_) {}` (silent swallow)는 금지 — 디버깅 가시성 확보를 위해 최소 로깅 필수

---

## 캐싱 전략 (Stale-While-Revalidate)

API 계층에서 **SWR(Stale-While-Revalidate)** 패턴을 적용하여 체감 응답 속도와 데이터 신선도를 동시에 확보

### 흐름

```
getMeal(date, mealType) 호출
  │
  ├── 캐시 있음 + 유효 (24h 이내)
  │     └── 즉시 반환 (cache hit)
  │
  ├── 캐시 있음 + 만료 (24h ~ 3일)
  │     ├── 만료된 캐시 즉시 반환 (stale)
  │     └── 백그라운드에서 _prefetchMonth() 실행 (revalidate)
  │
  ├── 캐시 있음 + 매우 오래됨 (3일+)
  │     └── 캐시 무효화, 새로 fetch
  │
  └── 캐시 없음
        ├── 온라인 → _prefetchMonth() 후 캐시에서 읽기
        └── 오프라인 → "인터넷에 연결하세요" 센티널 반환
```

### TTL 정책

| 데이터 | 유효 기간 | Stale 허용 | 빈 결과 TTL |
|--------|----------|-----------|------------|
| **급식** ([meal_data_api](api/meal_data_api.md)) | 24시간 | 3일까지 | 5분 |
| **시간표** ([timetable_data_api](api/timetable_data_api.md)) | 12시간 | — | 없음 |
| **학사일정** ([notice_data_api](api/notice_data_api.md)) | 12시간 | — | 없음 |
| **유저 프로필** ([auth_service](data/auth_service.md)) | 5분 | — | 없음 |

### 동시 요청 병합 (Completer 패턴)

```dart
static final Map<String, Future<void>> _prefetchingMonths = {};

static Future<void> _prefetchMonth(DateTime date) {
  final key = DateFormat('yyyyMM').format(date);
  return _prefetchingMonths[key] ??= _doFetch(key).whenComplete(
    () => _prefetchingMonths.remove(key),
  );
}
```

여러 화면에서 동시에 같은 월의 급식 데이터를 요청해도 API 호출은 1회만 발생. `Completer` 대신 `Map<key, Future>` 패턴 사용

### 센티널 문자열

캐시된 데이터가 "데이터 없음"인지 "실제 데이터"인지 구분하기 위해 [`ApiStrings`](data/api_strings.md) 상수 사용:

```dart
if (cached.meal != ApiStrings.mealNoData) { ... }
```

---

## 테스트 전략

### 4계층 테스트 피라미드

```
         ┌──────────┐
         │  Golden  │ ← 5개: 시각적 회귀 방지
         │  (PNG)   │
         ├──────────┤
         │  Widget  │ ← 17개: Mock Notifier 주입, 상태 분기 검증
         ├──────────┤
         │ Provider │ ← 17개: ProviderContainer, 위젯 없이 로직 검증
         ├──────────┤
         │   Unit   │ ← 258개: 모델/유틸/파서, 외부 의존 0
         ├──────────┤
         │   API    │ ← 39개: MockClient 주입, NEIS 파싱/캐시/오프라인
         ├──────────┤
         │Repository│ ← 8개: GetIt Mock 주입 패턴
         └──────────┘
         + Firestore Rules 34개 (에뮬레이터)
```

### 계층별 전략

| 계층 | Mock 방식 | 검증 대상 |
|------|----------|----------|
| **Unit** | 없음 (순수 함수) | 직렬화, 등급 변환, 파싱, 토크나이저, 버전 비교 |
| **API** | `MockClient` + `NetworkStatus.testOverride` | NEIS 급식/시간표/학사일정 파싱, 캐시 TTL, 오프라인 폴백 |
| **Provider** | `ProviderContainer` + override | AsyncNotifier 상태 전이 (loading → data → error) |
| **Widget** | `ProviderScope.overrides` + Mock Notifier | 로딩 스피너, 에러 메시지, 빈 상태, 데이터 렌더링 |
| **Golden** | `fake_cloud_firestore` | PostCard 5종 변종 (기본/좋아요/공지/+N/익명) PNG 비교 |
| **Repository** | `GetIt.I.registerSingleton(MockRepo())` | DI 패턴 데모, 인터페이스 계약 |
| **Firestore Rules** | `@firebase/rules-unit-testing` + 에뮬레이터 | 역할별 접근 제어, 카운터 delta ±1 강제, 필드 위조 차단 |

### Provider 테스트 race condition 회피

`invalidateSelf()` 대신 직접 state 교체 패턴 사용 — race condition 원천 차단:

```dart
// ❌ 간헐적 실패
await GradeManager.addExam(exam);
ref.invalidateSelf();  // 비동기 재조회 → race condition

// ✅ 안정적
final current = await future;
await GradeManager.addExam(exam);
state = AsyncData([...current, exam]);  // 동기적 state 교체
```

### CI 파이프라인

```
GitHub Actions push/PR
  ├── flutter analyze (정적 분석)
  ├── flutter test (344 tests, ~10초)
  ├── Codecov 커버리지 업로드
  └── master push 시 Android APK 빌드

별도 워크플로우:
  └── firebase emulators:exec → npm test (34 rules tests, ~4초)
```
