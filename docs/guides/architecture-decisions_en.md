# Architecture Decision Records (ADRs)

> 한국어: [architecture-decisions.md](./architecture-decisions.md)

Each entry captures *why this option rather than the alternatives*.

---

## ADR-01. State Management: Riverpod 2.5 (vs Provider / BLoC / GetX)

- **Chosen because**: compile-time safety (`ref.watch`), composition via `family`/`autoDispose`, AsyncNotifier shrinks loading/error branch boilerplate
- **Rejected**:
  - *Provider* — `Consumer` boilerplate compounds with depth, no AsyncValue
  - *BLoC* — stream-based ceremony (Event/State classes) even for simple CRUD, steep curve
  - *GetX* — bundles DI/navigation/i18n, lock-in risk
- **Trade-off**: `riverpod_generator` codegen dependency; we keep `ref` out of non-widget code by enforcing a separate Manager layer
- **Related files**: `lib/providers/*.dart`, `pubspec.yaml` (`flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`)

---

## ADR-02. Sensitive Data Storage: flutter_secure_storage (vs SharedPreferences)

- **Target**: grades (identifiable + sensitive in school context)
- **Chosen because**: delegates to Android Keystore / iOS Keychain for OS-level encryption. SharedPreferences stores plain XML/plist
- **Migration**: 1-time `migrateFromPlain` on first launch, old keys cleared; 8 regression tests guard
- **Rejected**: Firestore sync — grades are more trustworthy as *fully local*
- **Related files**: `lib/data/secure_storage_service.dart`, `test/secure_storage_service_test.dart`

---

## ADR-03. Board Search: Client-side n-gram Indexing (vs Algolia / Typesense / Client Filter)

- **Chosen because**: Firestore has no LIKE / full-text. On write we 2-gram the title+body into `searchTokens` → query via `array-contains-any`. No external search infra. Robust against Korean word-boundary ambiguity
- **Caps**: 200 tokens/doc, 10 tokens/query (Firestore `array-contains-any` limit = 30)
- **Rejected**:
  - *Algolia/Typesense* — monthly cost + extra infra, overkill at school-app scale
  - *Client filter* — only the paginated 20 items are searched, full-corpus impossible
- **Known limit**: token matching can produce false positives → post-fetch substring filter on the client
- **Related files**: `test/search_tokens_test.dart`, `test/search_history_service_test.dart`

---

## ADR-04. Like Counter: `Map<uid,bool>` + Denormalized int (vs Map-only / int-only)

- **Chosen because**: keep both representations. `likes: {uid: true}` → O(1) "did I like?" lookup. `likeCount: int` → sortable for Popular tab (`orderBy`)
- **Sync**: `_toggleLike` wraps `FieldValue.increment(±1)` + map dot-path write in a single transaction. Legacy docs lazy-backfill via `_ensureLikesMap` reading Map size
- **Rules**: `validCounterDelta('likeCount')` uses `resource.data.get(field, 0)` for backward compat and enforces ±1 delta
- **Rejected**:
  - *Map only* — Firestore can't `orderBy` array length
  - *int only* — "did I like?" needs a separate collection → read cost ↑
- **Related files**: `firestore.rules` (`validCounterDelta`), `firestore.indexes.json` (`likeCount DESC + createdAt DESC`)

---

## ADR-05. Charts: CustomPainter Directly (vs fl_chart / syncfusion)

- **Chosen because**: grade charts have *non-standard* requirements — inverted grade axis (lower = better), English/KoreanHistory absolute-grade branch, grade-cut dashed lines, per-subject colors. Painting on Canvas is simpler than shoehorning into a library wrapper
- **Pros**: zero deps, zero APK size impact
- **Trade-off**: poor reuse. Revisit fl_chart if we add more chart types (study stats, etc.)
- **Related files**: `lib/screens/sub/grade_screen.dart` (CustomPainter block)

---

## ADR-06. Storage Allocation: SQLite / Firestore / SecureStorage / Cloud Storage

| Store | Purpose | Rationale |
|---|---|---|
| **sqflite** | Personal schedules (time/color/span) | row-level range queries + offline-first |
| **Firestore** | Posts / comments / chats / reports / user profiles | realtime sync + multi-client + Cloud Functions triggers |
| **SecureStorage** | Grades | OS-level encryption + fully local |
| **Cloud Storage** | Post / profile images | CDN + direct download URLs |

One clear purpose per store → "where does this data live?" is never ambiguous. Schema details in [data-model_en.md](./data-model_en.md).

---

## ADR-07. DI: GetIt + Abstract Repository (vs Riverpod-only / get_it-only)

- **Chosen because**: Riverpod is widget-tree-bound, awkward in non-widget code (Managers, Cloud Function trigger handlers). GetIt is a service locator usable anywhere
- **Mixing rule**: widgets → Riverpod; Managers/Repositories → GetIt. Tests use `setupServiceLocator()` / `resetServiceLocator()` for mock injection
- **Rejected**:
  - *Riverpod alone* — passing `ref` around non-widget code is awkward
  - *GetIt alone* — no automatic widget rebuilds
- **Related files**: `test/auth_repository_test.dart` (gradual DI migration demo)

---

## ADR-08. Test Strategy: Unit + Provider + Widget + Rules (4 layers)

- **`test()` unit (470)**: models / utils / parsers / Provider / Repository / Golden. `ProviderContainer` verifies AsyncNotifier without a widget tree; mock injection keeps external deps at zero
- **`testWidgets()` widget (89)**: `ProviderScope.overrides` injects mock notifiers; loading / error / empty branches
- **Golden (`matchesGoldenFile`)**: PostCard snapshot PNG comparison (`fake_cloud_firestore` + tolerance comparator) — counted inside `test()`
- **Integration (4)**: `integration_test/` for app-level navigation E2E
- **Firestore Rules (85)**: `@firebase/rules-unit-testing` + emulator — validates rules themselves (regression-proof even without code changes); covers the 4-tier role matrix (`user`/`moderator`/`auditor`/`manager`/`admin`) and PIPA collections (`appeals`/`data_requests`/`community_rules`)
- **Rejected**: full integration with real Firebase Auth — CI cost ↑, flake ↑
- **Totals**: 563 (Flutter) + 85 (Rules) = **648**. Full breakdown in [testing_en.md](./testing_en.md)

---

## ADR-09. Role Model: 4 tiers + Firebase Auth Custom Claims (vs Single Firestore `role` Field Check)

- **Background**: The original model had `role: "user" | "manager"`. Manager could do everything from triaging reports to suspending users — meaning a student moderator inevitably ended up pressing the suspend button. Separately, Firestore rules called `get(/databases/.../users/$uid).data.role` on every request — every post read incurred one extra read for permission checking.
- **Decision**: Split roles into `user` / `moderator` / `auditor` / `manager` / `admin` (effectively 4 privilege tiers + regular user). Move the role into Firebase Auth **custom claims** so it ships in the ID token. Rules check `request.auth.token.role` directly → zero `get()` calls.
- **Permission matrix**:
  - `moderator` — handle reports, hide posts/comments. Cannot suspend.
  - `auditor` — read-only access to all reports / logs / stats. No writes (teacher audit-access scenario).
  - `manager` — suspend, pin notices, approve users.
  - `admin` — everything + change other users' roles.
- **Migration**: One-time backfill iterating all 28 existing users in the `users` collection, calling `setCustomUserClaims({role, approved})` (`scripts/backfill-claims.js`, local admin SDK).
- **Tradeoff**: Right after a role change, the client must call `getIdTokenResult(true)` to refresh the token / permission logic must stay in sync with token issuance.
- **Rejected**: Firestore role-field lookup — extra read per request; permission checks scale with data reads.
- **Files**: `firestore.rules`, `functions/index.js` (`onUserUpdated` / `backfillCustomClaims`), `tests/firestore-rules/test/rules.test.js`

---

## ADR-10. PIPA Compliance: TTL Collections + Automated Lifecycle (vs Manual Cleanup / Soft-Delete Flag)

- **Background**: Korea's Personal Information Protection Act (PIPA) requires three guarantees: (1) the right to appeal moderation decisions, (2) the right to download one's data, (3) explicit community rules. The hard part isn't the "Delete" button — it's making **expired data disappear without intervention**.
- **Decision**: Add 3 new collections (`appeals`, `data_requests`, `community_rules`). Add an `expiresAt` field to almost every new collection and bind a Firestore TTL policy to it. Once the timestamp passes, Firestore deletes the document on its own.
- **TTL policies**:
  - `appeals.expiresAt` — 90 days
  - `data_requests.expiresAt` — 30 days
  - `admin_logs.expiresAt` — 1 year (audit logs)
- **Data export**: `createDataExport` Cloud Function bundles the user's posts/comments/reports/chats into JSON, uploads to Storage, emails the download link, then `purgeExpiredExports` runs a daily cleanup.
- **Tradeoff**: TTL deletion runs ~once a day at non-deterministic times, so the exact expiry moment isn't guaranteed (sufficient for PIPA).
- **Rejected**:
  - *Manual cleanup* — a system that requires weekly hand-cleanup eventually doesn't get cleaned.
  - *Soft-delete flag* — data never actually disappears, failing PIPA's "destroy after retention" requirement.
- **Files**: `firestore.rules`, `firestore.indexes.json`, `functions/index.js` (`createDataExport` / `purgeExpiredExports`), `lib/screens/appeal/`, `lib/screens/data_request/`, `lib/screens/community_rules/`

---

## ADR-11. Dashboard Counters: Denormalized `app_stats/totals` (vs Client-Side `collection.count()`)

- **Background**: The admin dashboard shows totals and daily trends for `posts`, `users`, `reports`. Fetching the whole collection client-side meant thousands of reads on every page load (1k users baseline).
- **Decision**: Cloud Functions triggers (`onPostCreated` / `onUserCreated` / `onReportCreated`) call `FieldValue.increment(1)` on a single `app_stats/totals` document. Daily trends accumulate into `app_stats/daily_<YYYY-MM-DD>`. The dashboard reads one counter doc.
- **Tradeoff**: A missed trigger desyncs the counter — the `backfillStats` HTTP function recomputes from scratch.
- **Rejected**: `collection.count()` aggregation — still scans the collection per call; little cost reduction.
- **Files**: `functions/index.js` (`incrementStat` / `backfillStats`), `admin-web/app/page.tsx`
