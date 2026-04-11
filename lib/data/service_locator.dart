import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_repository.dart';
import 'package:hansol_high_school/data/grade_repository.dart';
import 'package:hansol_high_school/data/local_database.dart';

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

Future<void> resetServiceLocator() async {
  await GetIt.I.reset();
}
