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
│  │  Riverpod Providers (auth/grade/settings/theme)    │  │
│  │  + Legacy ValueNotifier (themeNotifier)            │  │
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

이 프로젝트는 **Riverpod 2.5**를 핵심 상태 관리 도구로 사용하되, 레거시 호환을 위해 일부 패턴이 공존한다

### 1. Riverpod AsyncNotifier / Notifier

가장 권장되는 패턴. 비동기 데이터를 `AsyncValue<T>`로 래핑해 로딩/에러/데이터 상태를 자동 관리한다

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

Firebase 실시간 데이터에 사용한다

```dart
// providers/auth_provider.dart
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
```

### 3. 파생 Provider

다른 Provider에서 계산된 값을 도출한다

```dart
final isManagerProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.isManager ?? false;
});
```

### 4. StreamBuilder (위젯 내 직접 사용)

Firestore 실시간 스트림은 대부분 위젯에서 직접 `StreamBuilder`로 소비한다
게시글 목록, 댓글, 채팅 메시지, 알림 등이 이 패턴이다

```dart
// board/post_detail_screen.dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance.doc('posts/$postId').snapshots(),
  builder: (context, snapshot) { ... },
)
```

### 5. FutureBuilder

1회성 비동기 데이터 로드에 사용한다

```dart
// meal_screen.dart
FutureBuilder<Meal?>(
  future: MealDataApi.getMeal(date: selectedDate, mealType: 2),
  builder: (context, snapshot) { ... },
)
```

### 6. 레거시: ValueNotifier + setState

일부 화면은 아직 `setState` 기반이다. `themeNotifier`는 Riverpod `themeProvider`와 양방향 동기화된다

```dart
// main.dart (레거시 ↔ Riverpod 동기화)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void _onThemeChanged() {
  final idx = ...;
  ref.read(themeProvider.notifier).setMode(idx);  // 레거시 → Riverpod
}
```

### 상태 관리 사용 가이드

| 데이터 유형 | 패턴 | 예시 |
|------------|------|------|
| 앱 전역 상태 | Riverpod Notifier/AsyncNotifier | 테마, 인증, 성적 |
| Firebase 실시간 데이터 | StreamBuilder | 게시글, 댓글, 채팅 |
| 1회성 API 호출 | FutureBuilder | 급식, 시간표 |
| 화면 로컬 상태 | setState | 입력 폼, 탭 인덱스 |
| 전역 이벤트 | ValueNotifier / StreamController | 앱 리프레시, 알림 딥링크 |

---

## 의존성 주입 (DI)

### GetIt 서비스 로케이터

`service_locator.dart`에서 앱 시작 시 싱글톤 서비스를 등록한다

```dart
Future<void> setupServiceLocator() async {
  GetIt.I.registerSingleton<AuthRepository>(FirebaseAuthRepository());
  GetIt.I.registerLazySingleton<GradeRepository>(() => LocalGradeRepository());
  
  final db = LocalDataBase();
  await db.migrateFromPrefs();
  GetIt.I.registerSingleton<LocalDataBase>(db);
}
```

**등록된 서비스**:
- [`AuthRepository`](data/auth_repository.md) → [`FirebaseAuthRepository`](data/auth_repository.md) (싱글톤)
- [`GradeRepository`](data/grade_repository.md) → [`LocalGradeRepository`](data/grade_repository.md) (레이지 싱글톤)
- [`LocalDataBase`](data/local_database.md) (싱글톤, 마이그레이션 후 등록)

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

## 테마 시스템

### 컬러 아키텍처

```
AppColors (abstract)
  ├── LightAppColors (싱글톤) - 라이트 모드 색상
  ├── DarkAppColors (싱글톤) - 다크 모드 색상
  └── AnimatedAppColors (싱글톤) - 색상 보간(lerp) 애니메이션
```

[`AnimatedAppColors`](styles/app_colors.md)는 라이트/다크 색상 사이를 0.0~1.0 progress로 보간한다:

```dart
AppColors.theme.primaryColor    // 현재 테마의 primary 색상
AppColors.theme.mealCardColor   // 급식 카드 배경색
```

### 테마 모드 관리

```
SettingData.themeModeIndex (SharedPreferences)
         │
         ├── themeNotifier (ValueNotifier<ThemeMode>) ← 레거시
         │
         └── themeProvider (Riverpod) ← 신규
                │
                └── AnimatedAppColors.setDark() → 컬러 보간
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

여러 데이터는 **로컬 우선 + Firestore 백업** 전략을 사용한다:

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

불변(immutable) 데이터 클래스를 자동 생성한다:

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

`build_runner`가 `meal.freezed.dart` + `meal.g.dart`를 생성한다

### Riverpod Generator

`@Riverpod` 어노테이션으로 Provider를 자동 생성한다:

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

### 네트워크 에러

- `OfflineBanner`: connectivity_plus로 네트워크 상태 감지, 오프라인 시 배너 표시
- 각 API 호출은 try/catch로 감싸고, 실패 시 빈 데이터 또는 캐시 반환

### Firebase 초기화 실패

main.dart에서 Firebase 초기화를 try/catch로 감싸 앱 자체는 항상 실행되도록 한다
