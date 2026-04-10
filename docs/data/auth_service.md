# AuthService

> `lib/data/auth_service.dart` — Firebase 인증 + 프로필 CRUD

`UserProfile` 모델과 `AuthService` 클래스를 포함. 모든 메서드가 `static`

---

## UserProfile (데이터 모델)

```dart
class UserProfile {
  final String uid;
  final String name;
  final String studentId;
  final int grade;
  final int classNum;
  final String email;
  final bool approved;
  final String role;           // 'user' | 'manager' | 'admin'
  final String userType;       // 'student' | 'graduate' | 'teacher' | 'parent'
  final String lastProfileUpdate;
  final int? graduationYear;
  final String? teacherSubject;
  final DateTime? suspendedUntil;
  final List<String> blockedUsers;
  final String loginProvider;
  final String? profilePhotoUrl;
}
```

### 계산 프로퍼티

| 프로퍼티 | 로직 |
|----------|------|
| `isManager` | `role == 'manager' \|\| role == 'admin'` |
| `isAdmin` | `role == 'admin'` |
| `isSuspended` | `suspendedUntil != null && DateTime.now().isBefore(suspendedUntil!)` |
| `displayName` | userType별 분기: 졸업생/교사/학부모 접두어, 학생은 `studentId + name` |
| `needsProfileUpdate` | 학생/교사만 해당, 3월 이후 `lastProfileUpdate`가 올해가 아니면 true |

---

## `signInWithGoogle`

```dart
static Future<User?> signInWithGoogle()
```

**설명**: Google 소셜 로그인으로 Firebase 인증을 수행한다

1. `GoogleSignIn().signIn()`으로 Google 계정 선택 팝업:
   ```dart
   final googleUser = await _googleSignIn.signIn();
   if (googleUser == null) return null;  // 사용자 취소
   ```

2. Google OAuth 토큰으로 Firebase credential 생성:
   ```dart
   final googleAuth = await googleUser.authentication;
   final credential = GoogleAuthProvider.credential(
     accessToken: googleAuth.accessToken,
     idToken: googleAuth.idToken,
   );
   ```

3. Firebase에 로그인 후 Analytics 이벤트 발행:
   ```dart
   final result = await _auth.signInWithCredential(credential);
   unawaited(AnalyticsService.logLogin('google'));
   unawaited(AnalyticsService.setUserId(result.user!.uid));
   ```

**반환값**: `User?` — 성공 시 Firebase User, 취소/에러 시 null

---

## `signInWithApple`

```dart
static Future<User?> signInWithApple()
```

**설명**: Apple 로그인을 수행한다. nonce 기반 보안 처리 포함

1. 보안용 랜덤 nonce 생성 및 SHA-256 해싱:
   ```dart
   final rawNonce = _generateNonce();
   final nonce = _sha256ofString(rawNonce);
   ```

2. Apple ID credential 요청 (email, fullName 스코프):
   ```dart
   final appleCredential = await SignInWithApple.getAppleIDCredential(
     scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
     nonce: nonce,
   );
   ```

3. OAuthProvider로 Firebase credential 변환 후 로그인:
   ```dart
   final oauthCredential = OAuthProvider('apple.com').credential(
     idToken: appleCredential.identityToken,
     rawNonce: rawNonce,
   );
   ```

4. 최초 로그인 시 Apple에서 제공한 이름을 displayName에 설정:
   ```dart
   if (appleCredential.givenName != null) {
     await result.user?.updateDisplayName(...);
   }
   ```

---

## `signInWithKakao`

```dart
static Future<User?> signInWithKakao(String kakaoAccessToken)
```

**설명**: 카카오 로그인. Cloud Function을 거쳐 Firebase Custom Token으로 변환한다

1. 카카오 SDK에서 받은 accessToken을 Cloud Function에 POST:
   ```dart
   final response = await http.post(
     Uri.parse('https://.../kakaoCustomAuth'),
     body: jsonEncode({'token': kakaoAccessToken}),
   );
   ```

2. Cloud Function이 반환한 Firebase Custom Token으로 로그인:
   ```dart
   final customToken = jsonDecode(response.body)['firebaseToken'] as String;
   final result = await _auth.signInWithCustomToken(customToken);
   ```

**파라미터**: `kakaoAccessToken` — 카카오 SDK `LoginResult`에서 얻은 액세스 토큰

---

## `signInWithGitHub`

```dart
static Future<User?> signInWithGitHub()
```

**설명**: GitHub 로그인. Firebase 내장 `signInWithProvider`를 사용한다

```dart
final githubProvider = GithubAuthProvider();
final result = await _auth.signInWithProvider(githubProvider);
```

별도 서버 없이 Firebase가 OAuth 플로우를 직접 처리

---

## `signOut`

```dart
static Future<void> signOut()
```

Google과 Firebase 모두 로그아웃. Analytics에 로그아웃 이벤트 발행

```dart
unawaited(AnalyticsService.logLogout());
await _googleSignIn.signOut();
await _auth.signOut();
```

---

## `getUserProfile`

```dart
static Future<UserProfile?> getUserProfile()
```

Firestore `users/{uid}` 문서에서 프로필을 조회한다. 캐시 없이 매번 직접 조회

---

## `saveUserProfile`

```dart
static Future<void> saveUserProfile(UserProfile profile)
```

Firestore `users/{uid}`에 프로필을 저장한다. `SetOptions(merge: true)`로 기존 필드 보존

---

## `hasProfile`

```dart
static Future<bool> hasProfile()
```

프로필 문서가 존재하고 `name` 필드가 있는지 확인. 로그인 직후 프로필 설정 화면 분기에 사용

---

## `isApproved`

```dart
static Future<bool> isApproved()
```

**설명**: 사용자가 승인 상태인지 확인한다

```dart
if (profile.isSuspended) return false;
return profile.approved || profile.isManager;
```

정지 상태면 `false`, 매니저/관리자는 승인 불필요

---

## `getSuspendedMessage`

```dart
static Future<String?> getSuspendedMessage()
```

**설명**: 정지 잔여 시간을 한국어 문자열로 반환한다

```dart
final diff = profile.suspendedUntil!.difference(DateTime.now());
// → "2일 3시간 15분" 형태
```

정지 상태가 아니면 null

---

## `getCachedProfile`

```dart
static Future<UserProfile?> getCachedProfile()
```

**설명**: 5분 TTL 메모리 캐시로 프로필을 조회한다

```dart
if (_cachedProfile != null && _cacheTime != null &&
    DateTime.now().difference(_cacheTime!).inMinutes < 5) {
  return _cachedProfile;
}
_cachedProfile = await getUserProfile();
_cacheTime = DateTime.now();
```

게시판 작성, 댓글 등 빈번한 프로필 참조 시 Firestore 호출을 줄임

---

## `clearProfileCache`

```dart
static void clearProfileCache()
```

프로필 수정 후 호출. `_cachedProfile`과 `_cacheTime`을 null로 초기화

---

## `refreshCustomClaims`

```dart
static Future<Map<String, dynamic>?> refreshCustomClaims()
```

**설명**: ID 토큰을 강제 갱신해 최신 Custom Claims를 가져온다

```dart
final result = await user.getIdTokenResult(true);  // forceRefresh
return result.claims;
```

Cloud Function `onUserUpdated`가 `setCustomUserClaims`를 호출한 뒤, 클라이언트에서 이 메서드를 호출해야 변경된 role/approved가 즉시 반영됨

---

## 내부 유틸리티

| 함수 | 설명 |
|------|------|
| `_generateNonce([length])` | 보안용 랜덤 문자열 생성 (Apple 로그인용) |
| `_sha256ofString(input)` | SHA-256 해시 (nonce 해싱) |
| `setCachedProfileForTest(profile)` | `@visibleForTesting` — 테스트용 캐시 주입 |
