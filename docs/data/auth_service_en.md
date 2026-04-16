# AuthService

> 한국어: [auth_service.md](./auth_service.md)

> `lib/data/auth_service.dart` — Firebase auth + profile CRUD

Contains the `UserProfile` model and the `AuthService` class. All methods are `static`.

---

## UserProfile (data model)

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

### Computed properties

| Property | Logic |
|----------|------|
| `isManager` | `role == 'manager' \|\| role == 'admin'` |
| `isAdmin` | `role == 'admin'` |
| `isSuspended` | `suspendedUntil != null && DateTime.now().isBefore(suspendedUntil!)` |
| `displayName` | Branches by userType: prefix for graduate/teacher/parent, student uses `studentId + name` |
| `needsProfileUpdate` | Only for students/teachers; true if after March and `lastProfileUpdate` is not in the current year |

---

## `signInWithGoogle`

```dart
static Future<User?> signInWithGoogle()
```

**Description**: Performs Firebase authentication via Google social login.

1. Show the Google account selection popup with `GoogleSignIn().signIn()`:
   ```dart
   final googleUser = await _googleSignIn.signIn();
   if (googleUser == null) return null;  // user cancelled
   ```

2. Create a Firebase credential with the Google OAuth tokens:
   ```dart
   final googleAuth = await googleUser.authentication;
   final credential = GoogleAuthProvider.credential(
     accessToken: googleAuth.accessToken,
     idToken: googleAuth.idToken,
   );
   ```

3. Sign in to Firebase and publish an Analytics event:
   ```dart
   final result = await _auth.signInWithCredential(credential);
   unawaited(AnalyticsService.logLogin('google'));
   unawaited(AnalyticsService.setUserId(result.user!.uid));
   ```

**Returns**: `User?` — Firebase User on success, null on cancel/error.

---

## `signInWithApple`

```dart
static Future<User?> signInWithApple()
```

**Description**: Performs Apple Sign In. Includes nonce-based security handling.

1. Generate a random security nonce and hash it with SHA-256:
   ```dart
   final rawNonce = _generateNonce();
   final nonce = _sha256ofString(rawNonce);
   ```

2. Request the Apple ID credential (email, fullName scopes):
   ```dart
   final appleCredential = await SignInWithApple.getAppleIDCredential(
     scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
     nonce: nonce,
   );
   ```

3. Convert to a Firebase credential via OAuthProvider and sign in:
   ```dart
   final oauthCredential = OAuthProvider('apple.com').credential(
     idToken: appleCredential.identityToken,
     rawNonce: rawNonce,
   );
   ```

4. On first login, set the name provided by Apple as the displayName:
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

**Description**: Kakao login. Converts to a Firebase Custom Token via a Cloud Function.

1. POST the accessToken received from the Kakao SDK to the Cloud Function:
   ```dart
   final response = await http.post(
     Uri.parse('https://.../kakaoCustomAuth'),
     body: jsonEncode({'token': kakaoAccessToken}),
   );
   ```

2. Sign in with the Firebase Custom Token returned by the Cloud Function:
   ```dart
   final customToken = jsonDecode(response.body)['firebaseToken'] as String;
   final result = await _auth.signInWithCustomToken(customToken);
   ```

**Parameters**: `kakaoAccessToken` — access token obtained from the Kakao SDK `LoginResult`.

---

## `signInWithGitHub`

```dart
static Future<User?> signInWithGitHub()
```

**Description**: GitHub login. Uses Firebase's built-in `signInWithProvider`.

```dart
final githubProvider = GithubAuthProvider();
final result = await _auth.signInWithProvider(githubProvider);
```

Firebase handles the OAuth flow directly without a separate server.

---

## `signOut`

```dart
static Future<void> signOut()
```

Sign out of both Google and Firebase. Publishes a logout event to Analytics.

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

Fetches the profile from the Firestore `users/{uid}` document. Queries directly every time without caching.

---

## `saveUserProfile`

```dart
static Future<void> saveUserProfile(UserProfile profile)
```

Saves the profile to Firestore `users/{uid}`. Preserves existing fields with `SetOptions(merge: true)`.

---

## `hasProfile`

```dart
static Future<bool> hasProfile()
```

Checks whether the profile document exists and has a `name` field. Used to branch to the profile setup screen immediately after login.

---

## `isApproved`

```dart
static Future<bool> isApproved()
```

**Description**: Checks whether the user is in approved status.

```dart
if (profile.isSuspended) return false;
return profile.approved || profile.isManager;
```

Returns `false` if suspended; managers/admins do not require approval.

---

## `getSuspendedMessage`

```dart
static Future<String?> getSuspendedMessage()
```

**Description**: Returns the remaining suspension time as a Korean string.

```dart
final diff = profile.suspendedUntil!.difference(DateTime.now());
// → "2일 3시간 15분" format
```

Returns null if not suspended.

---

## `getCachedProfile`

```dart
static Future<UserProfile?> getCachedProfile()
```

**Description**: Fetches the profile from a 5-minute TTL in-memory cache.

```dart
if (_cachedProfile != null && _cacheTime != null &&
    DateTime.now().difference(_cacheTime!).inMinutes < 5) {
  return _cachedProfile;
}
_cachedProfile = await getUserProfile();
_cacheTime = DateTime.now();
```

Reduces Firestore calls for frequent profile references in posting, commenting, etc.

---

## `clearProfileCache`

```dart
static void clearProfileCache()
```

Call after editing the profile. Resets `_cachedProfile` and `_cacheTime` to null.

---

## `refreshCustomClaims`

```dart
static Future<Map<String, dynamic>?> refreshCustomClaims()
```

**Description**: Force-refreshes the ID token to get the latest Custom Claims.

```dart
final result = await user.getIdTokenResult(true);  // forceRefresh
return result.claims;
```

After the Cloud Function `onUserUpdated` calls `setCustomUserClaims`, the client must call this method for the updated role/approved to take effect immediately.

---

## Internal utilities

| Function | Description |
|------|------|
| `_generateNonce([length])` | Generates a random security string (for Apple login) |
| `_sha256ofString(input)` | SHA-256 hash (for nonce hashing) |
| `setCachedProfileForTest(profile)` | `@visibleForTesting` — cache injection for testing |
