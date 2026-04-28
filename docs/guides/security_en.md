# Security Model

> 한국어: [security.md](./security.md)

Firestore rules, role-based access control, and privacy safeguards in one place. Source file: `firestore.rules`. Tests: `tests/firestore-rules/`.

## Core Principles

1. **Firestore rules are the single source of truth** — app and Admin Web run under the same rules
2. **Roles live only on the server** (`users/{uid}.role`). Clients read but cannot modify
3. **Per-field validation** — non-authors can still touch interaction fields
4. **Sensitive data never goes to the server** — grades live only in the OS keychain

## Helper Functions (firestore.rules)

```
function isSignedIn() { return request.auth != null; }

function isAdmin() {
  return isSignedIn() &&
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role == 'admin';
}

function isAdminOrManager() {
  return isSignedIn() && (
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role in ['admin', 'manager']
  );
}

function isModerator() {
  return isSignedIn() && (
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role in ['admin', 'manager', 'moderator']
  );
}

function isAuditor() {
  return isSignedIn() && (
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role in ['admin', 'manager', 'auditor']
  );
}

function isStaff() {
  return isSignedIn() && (
    get(/databases/$(db)/documents/users/$(auth.uid)).data.role in ['admin', 'manager', 'moderator', 'auditor']
  );
}

function isVerified() {
  return isSignedIn() &&
    get(/databases/$(db)/documents/users/$(auth.uid))
      .data.get('verificationStatus', 'verified') == 'verified';
}

function isNotSuspended() {
  return isSignedIn() && (
    get(/databases/$(db)/documents/users/$(auth.uid)).data.get('suspendedUntil', null) == null ||
    get(/databases/$(db)/documents/users/$(auth.uid)).data.suspendedUntil < request.time
  );
}

function canWrite() { return isVerified() && isNotSuspended(); }

function changedKeys() {
  return request.resource.data.diff(resource.data).affectedKeys();
}

function isInteractionUpdate() {
  return changedKeys().hasOnly(
    ['likes', 'dislikes', 'likeCount', 'dislikeCount',
     'pollVoters', 'commentCount',
     'anonymousMapping', 'anonymousCount', 'bookmarkedBy']
  );
}

function validCounterDelta(field) {
  return !(field in changedKeys()) || (
    request.resource.data[field] is int &&
    request.resource.data[field] >= 0 &&
    request.resource.data[field] - resource.data.get(field, 0) >= -1 &&
    request.resource.data[field] - resource.data.get(field, 0) <= 1
  );
}
```

## Per-collection Rules

### `users/{uid}`
- **read**: self or manager/admin
- **create**: any authed user
- **update**: self (but `role`/`suspendedUntil`/`approved` immutable), or manager/admin freely
- **delete**: self or admin
- **Subcollections**: `subjects`, `sync` → self only; `notifications` → self reads/updates/deletes, anyone may create (admin alerts)

### `posts/{postId}`
- **read**: public
- **create**: `authorUid == auth.uid` + title 1–200 chars + content ≤5000 chars
- **update**: author freely, OR non-author limited to `isInteractionUpdate()` + `validCounterDelta(±1)`
- **delete**: author or moderator+ (`isModerator()`)

### `posts/{postId}/comments/{commentId}`
- **delete**: author or moderator+ (`isModerator()`)

### `chats/{chatId}` + messages
- Only participants (`participants` array) can read/write
- Message `update` is only for deletion fields (`deleted`, `deletedFor`) — content tampering blocked

### `reports`
- **create**: authed users
- **read**: staff+ (`isStaff()` — admin, manager, moderator, auditor)
- **delete**: manager/admin (`isAdminOrManager()`)

### `admin_logs`
- **create**: moderator+ (`isModerator()`)
- **read**: staff+ (`isStaff()`)

### `app_stats`, `function_logs`, `crash_logs`
- **read**: auditor+ (`isAuditor()` — admin, manager, auditor)

### `app_feedbacks`, `council_feedbacks`
- **read**: auditor+ (`isAuditor()`)
- **update/delete**: manager/admin (`isAdminOrManager()`)

### `app_config/{key}`
- Public read (version check, popup); admin-only write

### Verification / Suspension Guard
- `posts` create, `comments` create, `reports` create, `chats/messages` create require `canWrite()` — blocks suspended/unverified users
- Legacy users (no `verificationStatus`/`suspendedUntil` field) are grandfathered through

### New Collections (PIPA compliance)
- `studentIds/{studentId}` — student ID occupancy index. Read: signed-in. Write: Cloud Functions only
- `otp_codes/{uid}` — school-email OTP. All client read/write denied
- `banned_devices/{installationId}` — block re-registration after suspension. Client denied
- `reports_queue/{postId}` — auto-aggregated report queue. Read: staff+, write: Functions
- `appeals/{appealId}` — suspension appeals. Suspended users may write under their own uid (bypasses canWrite), 500-char limit, status changes by admin/manager only
- `data_requests/{requestId}` — data portability / access requests. Create requires canWrite + own uid; read by self or manager+
- `teacher_invites/{inviteId}` — teacher invite codes. Issue by admin/manager, redemption by Functions
- `community_rules/{version}` — public read, admin/manager publish

## Rate Limiting

| Target | Method |
|---|---|
| Post creation | client-side 30s cooldown; rules only check title/content length |
| Comment creation | client-side 10s cooldown |
| Duplicate reports | `(postId, reporterUid)` composite index blocks duplicates |

Client-side guards are bypassable, so **the real defense is the per-field validation in rules**.

## Cloud Functions Security

- `kakaoCustomAuth`: zod schema (`KakaoAuthSchema`) validates input, verifies with Kakao, then issues a Firebase custom token
- Push triggers: check receiver's `users/{uid}.notiXxx` before sending ([technical-challenges_en.md#7](./technical-challenges_en.md#7-per-category-push-toggles-server-side-filter))
- Errors are written to `function_logs` via the `logError` helper

## Sensitive Data Handling

### Grades — local only
- `flutter_secure_storage` → Android Keystore / iOS Keychain
- No server upload, no Cloud Backup
- Plain SharedPreferences data → one-time migration on first launch, old keys cleared

### Profile Pictures
- **256px compression** before Cloud Storage upload
- Deleted alongside Storage files on account deletion

### Post Images
- **1080px compression + EXIF/GPS stripping** (`flutter_image_compress`)
- Uploaded to Storage; URLs saved in Firestore

### OAuth-only Auth
- No password storage (Google / Apple / Kakao / GitHub)
- Kakao alone needs a custom-token bridge (Firebase Auth has no direct provider)

## Privacy

- **Privacy policy** shown in-app (`AppLocalizations`-based l10n, `PrivacyPolicyScreen`); consent required at signup
- **Age confirmation checkbox** (must be 14+) at profile setup (PIPA Article 22-2)
- "View full policy" link opens the complete privacy policy during signup
- **Analytics opt-out toggle** in settings (PIPA Article 10)
- Minimal collection: name / student ID / email / profile picture (school context essentials)
- D-day data (dates + labels) is non-sensitive and synced to Firestore (account-linked)
- **Immediate wipe on deletion** — collections + Storage + Auth in order ([technical-challenges_en.md#10](./technical-challenges_en.md#10-account-deletion-ordering-auth--firestore-permission-loss))
- **TTL cleanup**: stale logs/reports swept by the `cleanupOldPosts` scheduler

## Crash / Audit

- **Crashlytics** (Firebase console)
- `function_logs` (Cloud Functions error mirror)
- `admin_logs` (every admin action: who, when, what, before→after)

## Testing

- `tests/firestore-rules/`: `@firebase/rules-unit-testing` + emulator, 80 tests
- Covers permission bypass / counter forgery / field forgery at CI time
- Run: see [testing_en.md](./testing_en.md) + [cicd-setup_en.md](./cicd-setup_en.md)

## See Also
- [Data Model](./data-model_en.md)
- [Architecture Decisions](./architecture-decisions_en.md)
- [Account & Access](./account-and-access_en.md)
- [Deployment Guide](../DEPLOY_en.md) — rules deploy commands
