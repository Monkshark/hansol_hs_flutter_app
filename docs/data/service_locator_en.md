# ServiceLocator

> 한국어: [service_locator.md](./service_locator.md)

> `lib/data/service_locator.dart` — GetIt DI configuration

Called once at app startup to register dependencies.

---

## `setupServiceLocator`

```dart
Future<void> setupServiceLocator()
```

**Description**: Registers Repositories and services into the GetIt container.

```dart
final getIt = GetIt.I;

if (!getIt.isRegistered<AuthRepository>()) {
  getIt.registerLazySingleton<AuthRepository>(
    () => const FirebaseAuthRepository(),
  );
}

if (!getIt.isRegistered<GradeRepository>()) {
  getIt.registerLazySingleton<GradeRepository>(
    () => const LocalGradeRepository(),
  );
}

if (!getIt.isRegistered<LocalDataBase>()) {
  final localDb = LocalDataBase();
  await localDb.migrateFromPrefs();       // SharedPreferences → SQLite migration
  getIt.registerSingleton<LocalDataBase>(localDb);
}
```

- The `isRegistered` check prevents duplicate registration (safe to call multiple times in tests)
- [`AuthRepository`](auth_repository.md) and [`GradeRepository`](grade_repository.md) are `LazySingleton` (created on first access)
- [`LocalDataBase`](local_database.md) is created eagerly and runs migration

**Call site**: Called from `main()` after Firebase initialization.

---

## `resetServiceLocator`

```dart
Future<void> resetServiceLocator()
```

Test-only helper. Resets all registrations via `GetIt.I.reset()`.

```dart
// In test setUp:
await resetServiceLocator();
// register mocks
GetIt.I.registerSingleton<AuthRepository>(MockAuthRepository());
```

---

## Design note

> The canonical approach is to expose repositories through dedicated Providers (e.g., `ref.read(authRepositoryProvider)`) instead of calling `GetIt.I<AuthRepository>()` inside Riverpod Providers,
> but since this project is in a gradual migration phase, coexistence of GetIt + Riverpod is allowed.
