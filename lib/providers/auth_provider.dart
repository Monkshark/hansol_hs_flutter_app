import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/auth_service.dart';

/// Riverpod 인증/프로필 상태 Provider
///
/// - [authStateProvider]: Firebase Auth 상태 스트림
/// - [userProfileProvider]: AsyncNotifier 기반 프로필 상태
///   - 5분 캐시 내장 (별도 정적 캐시 제거)
///   - `refresh()` / `update()` 로 명시적 무효화
/// - [isLoggedInProvider], [isManagerProvider], [isAdminProvider]:
///   파생 Provider (자동 재계산)
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// 사용자 프로필 AsyncNotifier
///
/// 인증 상태 변경 시 자동 재조회.
/// 호출처에서 `ref.watch(userProfileProvider)`로 AsyncValue 소비.
class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      data: (user) async {
        if (user == null) return null;
        return AuthService.getUserProfile();
      },
      loading: () => null,
      error: (_, __) => null,
    );
  }

  /// 강제 새로고침 (프로필 수정 후 호출)
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      AuthService.clearProfileCache();
      return AuthService.getUserProfile();
    });
  }

  /// 낙관적 업데이트 (서버 저장 + 로컬 상태 즉시 반영)
  ///
  /// `AsyncNotifier.update`와 이름 충돌을 피하기 위해 `save`로 명명.
  Future<void> save(UserProfile profile) async {
    state = AsyncData(profile);
    await AuthService.saveUserProfile(profile);
    AuthService.clearProfileCache();
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);

final isLoggedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.maybeWhen(data: (user) => user != null, orElse: () => false);
});

final isManagerProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.maybeWhen(
    data: (p) => p?.isManager ?? false,
    orElse: () => false,
  );
});

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.maybeWhen(
    data: (p) => p?.isAdmin ?? false,
    orElse: () => false,
  );
});

final isSuspendedProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider);
  return profile.maybeWhen(
    data: (p) => p?.isSuspended ?? false,
    orElse: () => false,
  );
});
