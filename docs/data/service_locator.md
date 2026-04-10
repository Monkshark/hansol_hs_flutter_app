# ServiceLocator

> `lib/data/service_locator.dart` — GetIt DI 설정

앱 시작 시 한 번 호출하여 의존성을 등록한다

---

## `setupServiceLocator`

```dart
Future<void> setupServiceLocator()
```

**설명**: GetIt 컨테이너에 Repository와 서비스를 등록한다

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
  await localDb.migrateFromPrefs();       // SharedPreferences → SQLite 마이그레이션
  getIt.registerSingleton<LocalDataBase>(localDb);
}
```

- `isRegistered` 체크로 중복 등록 방지 (테스트에서 여러 번 호출해도 안전)
- [`AuthRepository`](auth_repository.md), [`GradeRepository`](grade_repository.md)는 `LazySignleton` (처음 접근 시 생성)
- [`LocalDataBase`](local_database.md)는 즉시 생성 + 마이그레이션 실행

**호출 위치**: `main()` 함수에서 Firebase 초기화 후 호출

---

## `resetServiceLocator`

```dart
Future<void> resetServiceLocator()
```

테스트용 헬퍼. `GetIt.I.reset()`으로 모든 등록을 초기화

```dart
// 테스트 setUp에서:
await resetServiceLocator();
// mock 등록
GetIt.I.registerSingleton<AuthRepository>(MockAuthRepository());
```

---

## 설계 참고

> Riverpod Provider 내부에서 `GetIt.I<AuthRepository>()`로 접근하지 않고,
> `ref.read(authRepositoryProvider)` 형태로 별도 Provider를 두는 것이 정석이지만,
> 점진적 마이그레이션 단계라 GetIt + Riverpod 병행을 허용
