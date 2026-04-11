import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_service.dart';

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

AuthRepository get authRepository => GetIt.I<AuthRepository>();
