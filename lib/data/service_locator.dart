import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_repository.dart';
import 'package:hansol_high_school/data/grade_repository.dart';
import 'package:hansol_high_school/data/local_database.dart';

/// 의존성 주입 컨테이너 설정
///
/// 앱 시작 시 한 번 호출. 모든 Repository / 서비스를 GetIt에 등록한다.
/// 테스트에서는 `setUp` 단계에서 `GetIt.I.reset()` 후 mock으로 교체하면 된다.
///
/// Riverpod Provider 내부에서도 `GetIt.I<AuthRepository>()`로 접근하지 않고,
/// `ref.read(authRepositoryProvider)` 형태로 별도 Provider를 두는 것이 정석이지만,
/// 여기서는 점진적 마이그레이션 단계라 GetIt + Riverpod 병행을 허용한다.
Future<void> setupServiceLocator() async {
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
    await localDb.migrateFromPrefs();
    getIt.registerSingleton<LocalDataBase>(localDb);
  }
}

/// 테스트용 헬퍼 — `setUp`에서 호출.
Future<void> resetServiceLocator() async {
  await GetIt.I.reset();
}
