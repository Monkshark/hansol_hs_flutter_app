# Architecture Decision Records (ADRs)

> 한국어: [architecture-decisions.md](./architecture-decisions.md)

Each entry captures *why this option rather than the alternatives*. New ADRs follow the template at the bottom.

## Index

- [ADR-01. State Management: Riverpod 2.5](#adr-01-state-management-riverpod-25)
- [ADR-02. Sensitive Data Storage: flutter_secure_storage](#adr-02-sensitive-data-storage-flutter_secure_storage)
- [ADR-03. Board Search: Client-side n-gram Indexing](#adr-03-board-search-client-side-n-gram-indexing)
- [ADR-04. Like Counter: `Map<uid,bool>` + Denormalized int](#adr-04-like-counter-mapuidbool--denormalized-int)
- [ADR-05. Charts: CustomPainter Directly](#adr-05-charts-custompainter-directly)
- [ADR-06. Storage Allocation](#adr-06-storage-allocation)
- [ADR-07. DI: GetIt + Abstract Repository](#adr-07-di-getit--abstract-repository)
- [ADR-08. Test Strategy: Unit + Provider + Widget + Rules](#adr-08-test-strategy-unit--provider--widget--rules)

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

- **`test()` unit (440)**: models / utils / parsers / Provider / Repository / Golden. `ProviderContainer` verifies AsyncNotifier without a widget tree; mock injection keeps external deps at zero
- **`testWidgets()` widget (80)**: `ProviderScope.overrides` injects mock notifiers; loading / error / empty branches
- **Golden (`matchesGoldenFile`)**: PostCard snapshot PNG comparison (`fake_cloud_firestore` + tolerance comparator) — counted inside `test()`
- **Integration (4)**: `integration_test/` for app-level navigation E2E
- **Firestore Rules (34)**: `@firebase/rules-unit-testing` + emulator — validates rules themselves (regression-proof even without code changes)
- **Rejected**: full integration with real Firebase Auth — CI cost ↑, flake ↑
- **Totals**: 524 (Flutter) + 34 (Rules) = **558**. Full breakdown in [testing_en.md](./testing_en.md)

---

## Template for New ADRs

```md
## ADR-NN. Decision Title (vs alt1 / alt2)

- **Chosen because**: one or two sentences
- **Rejected**:
  - *alt1* — why it lost
  - *alt2* — why it lost
- **Trade-off**: what the choice costs
- **Related files**: `path/to/file.dart`, `path/to/other.rules`
```

- Number = previous max + 1
- Emphasize *why not the alternative* more than *why this*
