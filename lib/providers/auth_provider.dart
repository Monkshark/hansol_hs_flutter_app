/// Riverpod 인증 상태 Provider
///
/// - authStateProvider: Firebase Auth 상태 스트림
/// - userProfileProvider: Firestore 사용자 프로필 조회
/// - isLoggedInProvider: 로그인 여부 판별
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) async {
      if (user == null) return null;
      return AuthService.getUserProfile();
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (_, __) => false,
  );
});

final isManagerProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.when(
    data: (p) => p?.isManager ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});
