# AuthRepository

> 한국어: [auth_repository.md](./auth_repository.md)

> `lib/data/auth_repository.dart` — Auth/profile Repository interface

Wraps the static methods of [`AuthService`](auth_service_en.md) as instance methods and registers them with GetIt DI. Allows mock injection in tests.

---

## Design background

```
AuthService (static methods, called directly from 25 files)
    ↑
AuthRepository (instance interface)
    ↑
FirebaseAuthRepository (delegates to AuthService)
```

> 📎 [`AuthService`](auth_service_en.md)

Removing the static methods all at once would require modifying 25 files simultaneously, so the two interfaces run **in parallel**:
- **New code / Riverpod Providers** → use `AuthRepository`
- **Existing call sites** → call [`AuthService`](auth_service_en.md) directly (gradual migration)

---

## `AuthRepository` (abstract class)

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

Only the core methods of [`AuthService`](auth_service_en.md) are extracted into the interface. Login methods (signInWithGoogle, etc.) are called directly only from the UI and are excluded.

---

## `FirebaseAuthRepository` (default implementation)

```dart
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  @override
  User? get currentUser => AuthService.currentUser;

  @override
  Future<UserProfile?> getUserProfile() => AuthService.getUserProfile();

  @override
  Future<UserProfile?> getCachedProfile() => AuthService.getCachedProfile();

  // ... all remaining methods delegate to AuthService static methods
}
```

Every method calls an [`AuthService`](auth_service_en.md) static method directly. `const` constructor means no instance creation cost.

---

## GetIt accessor

```dart
AuthRepository get authRepository => GetIt.I<AuthRepository>();
```

Global getter. Registered as `FirebaseAuthRepository` in `service_locator.dart`:
```dart
getIt.registerLazySingleton<AuthRepository>(
  () => const FirebaseAuthRepository(),
);
```

---

## Test usage

```dart
// test setUp
await resetServiceLocator();
GetIt.I.registerSingleton<AuthRepository>(MockAuthRepository());

// or Riverpod overrides
ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
  child: ...,
);
```

Injecting `MockAuthRepository` enables unit testing without Firestore/Firebase Auth dependencies.
