# AuthRepository

> `lib/data/auth_repository.dart` — 인증/프로필 Repository 인터페이스

[`AuthService`](auth_service.md)의 정적 메서드를 인스턴스 메서드로 감싸 GetIt DI에 등록. 테스트에서 mock 주입 가능.

---

## 설계 배경

```
AuthService (정적 메서드, 25개 파일에서 직접 호출)
    ↑
AuthRepository (인스턴스 인터페이스)
    ↑
FirebaseAuthRepository (AuthService에 위임)
```

> [`AuthService`](auth_service.md)

정적 메서드를 한 번에 제거하면 25개 파일을 동시에 수정해야 하므로, 두 인터페이스를 **병행**:
- **신규 코드 / Riverpod Provider** → `AuthRepository` 사용
- **기존 호출처** → [`AuthService`](auth_service.md) 직접 호출 (점진적 마이그레이션)

---

## `AuthRepository` (추상 클래스)

```dart
abstract class AuthRepository {
  User? get currentUser;
  bool get isLoggedIn;

  Future<UserProfile?> getUserProfile();
  Future<UserProfile?> getCachedProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<bool> hasProfile();
  Future<bool> isApproved();
  Future<bool> isManager();
  Future<void> signOut();
  void clearProfileCache();
}
```

`AuthService`의 핵심 메서드만 인터페이스로 추출. 로그인 메서드(signInWithGoogle 등)는 UI에서만 직접 호출하므로 제외.

---

## `FirebaseAuthRepository` (기본 구현)

```dart
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  @override
  User? get currentUser => AuthService.currentUser;

  @override
  Future<UserProfile?> getUserProfile() => AuthService.getUserProfile();

  @override
  Future<UserProfile?> getCachedProfile() => AuthService.getCachedProfile();

  // ... 나머지 모두 AuthService 정적 메서드에 위임
}
```

모든 메서드가 `AuthService`의 정적 메서드를 그대로 호출. `const` 생성자로 인스턴스 생성 비용 없음.

---

## GetIt 접근자

```dart
AuthRepository get authRepository => GetIt.I<AuthRepository>();
```

전역 getter. `service_locator.dart`에서 `FirebaseAuthRepository`로 등록됨:
```dart
getIt.registerLazySingleton<AuthRepository>(
  () => const FirebaseAuthRepository(),
);
```

---

## 테스트 활용

```dart
// test setUp
await resetServiceLocator();
GetIt.I.registerSingleton<AuthRepository>(MockAuthRepository());

// 또는 Riverpod overrides
ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
  child: ...,
);
```

`MockAuthRepository`를 주입해 Firestore/Firebase Auth 의존 없이 단위 테스트 가능.
