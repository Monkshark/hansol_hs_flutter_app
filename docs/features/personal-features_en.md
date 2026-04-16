# Personal Features (Grades / Schedule / Profile)

> 한국어: [personal-features.md](./personal-features.md)

Features handling personal user data. Grades are fully local, personal schedules live in sqflite, and profiles live in Firestore.

## Grade Management

### Tab Layout

- **Susi (internal) / Jeongsi (standardized)** tabs, swipe-switchable
- **Internal**: 5-grade system + A–E achievement tiers, per the 2022 curriculum revision
- **Standardized**: 2022-curriculum subjects (Korean / Math / English / Korean History / Integrated Social Studies / Integrated Science + second foreign language)
- **Private practice exams** supported

### Visualization

- **Trend chart**: `CustomPainter` line chart ([ADR-05](../guides/architecture-decisions_en.md#adr-05-charts-custompainter-directly))
  - Toggle modes: grade / raw score / percentile / standard score
  - Correctly renders inverted grade axis (lower = better)
- **Per-subject goals** — grade (0.1 step for susi) / percentile (for jeongsi), managed separately
- **Percentile → grade auto-conversion** (with dashed grade-cut lines)
- **English / Korean History** (absolute-grade subjects) exclude percentile goals
- Per-subject colors fixed in `lib/data/`

### Storage

- **Grades stored locally only** — never uploaded (`flutter_secure_storage`, [ADR-02](../guides/architecture-decisions_en.md#adr-02-sensitive-data-storage-flutter_secure_storage))
- Android Keystore / iOS Keychain delegation
- Plain legacy data → one-time migration on first launch

**Files**: `lib/screens/sub/grade_screen.dart`, `grade_input_screen.dart`, `lib/providers/grade_provider.dart`, `test/grade_manager_test.dart`, `test/secure_storage_service_test.dart`

## Personal Schedule

- Integrated with the **custom monthly calendar** (see Public Features)
- Single-day / multi-day, 6 presets + circular color picker
- **sqflite** storage — offline-first, fast range queries
- Visually distinct from NEIS academic events (dot vs bar)

**Files**: `test/schedule_data_test.dart`

## D-day

- Days remaining until a target date
- **Home-screen pinning** supported
- sqflite-backed (same DB as schedules)

**Files**: `lib/screens/sub/dday_screen.dart`, `test/dday_manager_test.dart`

## Profile / Settings

- **Profile picture** (uploaded to Cloud Storage, 256px compression)
- Privacy consent, onboarding → login flow
- Notification toggles — 5 categories (see [Community Features notifications](./community-features_en.md#notifications))
- Theme (light / dark / system)
- Meal notification time

**Files**: `lib/screens/auth/profile_edit_screen.dart`, `profile_setup_screen.dart`, `lib/screens/sub/setting_screen.dart`, `notification_setting_screen.dart`, `onboarding_screen.dart`

## New School-Year Update

- Students/teachers see a March popup to update year/class/number
- **Identity not user-changeable** (admin only — see [security_en.md](../guides/security_en.md))

## Deletion

Double-confirmation dialog → full wipe:
1. Delete subcollections (`users/{uid}/{subjects,sync,notifications}`)
2. Delete `users/{uid}` document (while still authed)
3. Delete Cloud Storage profile picture
4. `user.delete()` — delete Auth account

Order matters — Auth first causes PERMISSION_DENIED ([Technical Challenge #10](../guides/technical-challenges_en.md#10-account-deletion-ordering-auth--firestore-permission-loss)).

## See Also
- [Public Features](./public-features_en.md)
- [Community Features](./community-features_en.md)
- [Admin Features](./admin-features_en.md)
- [Account & Access](../guides/account-and-access_en.md)
- [Security Model](../guides/security_en.md)
