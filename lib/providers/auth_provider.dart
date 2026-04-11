import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hansol_high_school/data/auth_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      AuthService.clearProfileCache();
      return AuthService.getUserProfile();
    });
  }

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
