import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_service.dart';

/// 인증/프로필 도메인의 인스턴스 기반 Repository.
///
/// `AuthService`의 정적 메서드를 인스턴스 메서드로 감싸 GetIt에 등록한다.
/// 테스트에서 `GetIt.I.registerSingleton<AuthRepository>(MockAuthRepository())`
/// 로 mock 주입이 가능해진다.
///
/// 정적 메서드를 한 번에 제거하면 25개 파일을 동시에 수정해야 하므로
/// 두 인터페이스를 병행한다 — 신규 코드/Riverpod Provider는 이 클래스를 사용하고,
/// 기존 호출처는 점진적으로 마이그레이션한다.
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

/// 기본 구현 — `AuthService` 정적 메서드에 위임.
class FirebaseAuthRepository implements AuthRepository {
  const FirebaseAuthRepository();

  @override
  User? get currentUser => AuthService.currentUser;

  @override
  bool get isLoggedIn => AuthService.isLoggedIn;

  @override
  Future<UserProfile?> getUserProfile() => AuthService.getUserProfile();

  @override
  Future<UserProfile?> getCachedProfile() => AuthService.getCachedProfile();

  @override
  Future<void> saveUserProfile(UserProfile profile) =>
      AuthService.saveUserProfile(profile);

  @override
  Future<bool> hasProfile() => AuthService.hasProfile();

  @override
  Future<bool> isApproved() => AuthService.isApproved();

  @override
  Future<bool> isManager() => AuthService.isManager();

  @override
  Future<void> signOut() => AuthService.signOut();

  @override
  void clearProfileCache() => AuthService.clearProfileCache();
}

/// GetIt 진입점.
AuthRepository get authRepository => GetIt.I<AuthRepository>();
