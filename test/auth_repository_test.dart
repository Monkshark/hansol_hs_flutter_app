import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/auth_repository.dart';
import 'package:hansol_high_school/data/auth_service.dart';

/// AuthRepository (DI 인터페이스) 테스트
///
/// GetIt + Mock 패턴을 검증한다. 실제 Firebase에 의존하지 않고
/// AuthRepository를 mock으로 교체할 수 있는지가 핵심.
void main() {
  setUp(() async {
    if (GetIt.I.isRegistered<AuthRepository>()) {
      await GetIt.I.unregister<AuthRepository>();
    }
  });

  test('GetIt에 등록된 AuthRepository를 mock으로 교체 가능', () async {
    final mock = _MockAuthRepository();
    GetIt.I.registerSingleton<AuthRepository>(mock);

    final repo = authRepository;
    expect(repo.isLoggedIn, true);
    expect(repo.currentUser, isNull);

    final profile = await repo.getUserProfile();
    expect(profile, isNotNull);
    expect(profile!.name, 'Mock 사용자');
    expect(profile.role, 'manager');
    expect(profile.isManager, true);
  });

  test('mock signOut 호출 카운트', () async {
    final mock = _MockAuthRepository();
    GetIt.I.registerSingleton<AuthRepository>(mock);

    await authRepository.signOut();
    await authRepository.signOut();

    expect(mock.signOutCalls, 2);
  });

  test('mock saveUserProfile 데이터 캡처', () async {
    final mock = _MockAuthRepository();
    GetIt.I.registerSingleton<AuthRepository>(mock);

    final p = UserProfile(
      uid: 'u1',
      name: '테스트',
      studentId: '10101',
      grade: 1,
      classNum: 1,
      email: 't@t.com',
    );
    await authRepository.saveUserProfile(p);

    expect(mock.savedProfiles.length, 1);
    expect(mock.savedProfiles.first.uid, 'u1');
    expect(mock.savedProfiles.first.name, '테스트');
  });

  test('clearProfileCache는 mock에서도 동작', () {
    final mock = _MockAuthRepository();
    GetIt.I.registerSingleton<AuthRepository>(mock);

    authRepository.clearProfileCache();
    expect(mock.cacheCleared, true);
  });
}

class _MockAuthRepository implements AuthRepository {
  int signOutCalls = 0;
  bool cacheCleared = false;
  final List<UserProfile> savedProfiles = [];

  @override
  User? get currentUser => null;

  @override
  bool get isLoggedIn => true;

  @override
  Future<UserProfile?> getUserProfile() async => UserProfile(
        uid: 'mock',
        name: 'Mock 사용자',
        studentId: '20101',
        grade: 2,
        classNum: 1,
        email: 'mock@test.com',
        role: 'manager',
        approved: true,
      );

  @override
  Future<UserProfile?> getCachedProfile() => getUserProfile();

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    savedProfiles.add(profile);
  }

  @override
  Future<bool> hasProfile() async => true;

  @override
  Future<bool> isApproved() async => true;

  @override
  Future<bool> isManager() async => true;

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }

  @override
  void clearProfileCache() {
    cacheCleared = true;
  }
}
