# Hansol High School App

> 한국어: [README.md](./README.md)

[![Flutter CI](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/flutter.yml/badge.svg)](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/flutter.yml)
[![Firestore Rules Tests](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/firestore-rules.yml/badge.svg)](https://github.com/Monkshark/hansol_hs_flutter_app/actions/workflows/firestore-rules.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)
![Tests](https://img.shields.io/badge/tests-146%20unit%20%2B%2034%20rules-success)
![Riverpod](https://img.shields.io/badge/state-Riverpod%202.5-00b894)
![Firebase](https://img.shields.io/badge/backend-Firebase-FFCA28?logo=firebase&logoColor=black)
[![Riverpod Graph](https://img.shields.io/badge/Riverpod%20Graph-Interactive-6c5ce7?logo=d3.js&logoColor=white)](https://monkshark.github.io/hansol_hs_flutter_app/riverpod_graph.html)

> An integrated school platform for students, teachers, alumni, and parents of Hansol High School (Sejong, Korea).

A full-stack project with a Flutter mobile app + Next.js admin dashboard. Features NEIS public-data API integration, Firebase real-time database, role-based access control, push notifications, 1:1 chat — at a production-service level.

## Documentation Hub

Documentation is split by topic. Jump in based on your purpose.

### First-time Contributors
1. [Product Overview](./docs/product-overview_en.md)
2. [Architecture Overview](./docs/architecture-overview_en.md)
3. [Architecture Decisions (ADRs)](./docs/architecture-decisions_en.md)
4. Feature deep-dives: [Public](./docs/features/public-features_en.md) / [Community](./docs/features/community-features_en.md) / [Personal](./docs/features/personal-features_en.md) / [Admin](./docs/features/admin-features_en.md)
5. [Contributing Guide](./CONTRIBUTING_en.md)

### End Users (Students / Teachers / Alumni / Parents)
- [User Guide](./USER_GUIDE_en.md)
- [Public Features](./docs/features/public-features_en.md)
- [Account & Access](./docs/account-and-access_en.md)

### Operations / Deployment
- [Deployment Guide](./DEPLOY_en.md)
- [CI/CD Setup](./docs/cicd-setup_en.md)
- [Security Model](./docs/security_en.md)
- [Architecture Overview](./docs/architecture-overview_en.md)

### Further Reading
- [Data Model](./docs/data-model_en.md)
- [Testing Strategy](./docs/testing_en.md)
- [Technical Challenges (14 cases)](./docs/technical-challenges_en.md)
- [Screenshots Gallery](./docs/screenshots-gallery_en.md)

## Screenshots (Summary)

| Home | Board | Chat | Timetable |
|:--:|:--:|:--:|:--:|
| ![Home](screenshots/home.png) | ![Board](screenshots/board.png) | ![Chat](screenshots/chat_room.png) | ![Timetable](screenshots/timetable.png) |

| Meal | Search Results | Grades (Susi) | Admin Web |
|:--:|:--:|:--:|:--:|
| ![Meal](screenshots/meal.png) | ![Search](screenshots/board_search_results.png) | ![Grades](screenshots/susi.png) | ![Web](screenshots/admin_web.png) |

Full gallery → [Screenshots Gallery](./docs/screenshots-gallery_en.md)

## Metrics

| Metric | Value | Notes |
|---|---|---|
| **Total LOC** | **26,200+** | Dart 22,367 + TypeScript 1,882 + Java/XML 887 + Swift 330 + JS 737 |
| **Source files** | **91** (Flutter) + **12** (Admin Web) + **5** (Android Widget) + **1** (iOS Widget) | 27 screens, 15 extracted widgets, 49 models/utils/services |
| **Cloud Functions** | **8** | Push, OAuth, scheduler, account deletion |
| **OAuth providers** | **4** | Google, Apple, Kakao, GitHub |
| **Push notifications** | **13 types** | FCM 10 + local 3, per-category on/off |
| **Tests** | **146 + 34** | Flutter unit/widget/provider/golden 146 + Firestore rules emulator 34 (180 total) |
| **State management** | **Riverpod 2.5** | AsyncNotifier/Notifier + GetIt + repository DI |
| **Image compression** | **~70% reduction** | Posts: 1080px w/ EXIF/GPS stripped, profiles: 256px |
| **Search** | **Firestore n-gram index** | Title+body 2-gram `array-contains-any`, 350ms debounce |
| **Sensitive data** | **flutter_secure_storage** | Grades live in Android Keystore / iOS Keychain only |
| **API optimization** | **30 calls → 1** | Monthly prefetch + Completer pattern |
| **Firestore reads** | **30–50% reduction** | Offline cache + `limit()` optimization |
| **Operating cost** | **$0–3/month** | ~1,000 users, within free tier |

### Performance / Size (measured)

| Item | Value | Method |
|---|---|---|
| **Release APK** | **27 MB** | `build/app/outputs/flutter-apk/app-release.apk` (universal) |
| **Dart LOC** | **22,576** | `find lib -name '*.dart' \| xargs cat \| wc -l` |
| **Dart files** | **101** | `find lib -name '*.dart' \| wc -l` |
| **Unit/widget test time** | **~3s** | `flutter test` 131 tests, local machine |
| **Rules test time** | **~4s** | `firebase emulators:exec ... npm test` 34 tests |
| **Compressed image size** | **~30% of original** | 1080px wide, JPEG q80, EXIF stripped |
| **Search fetch limit** | **50 / 350ms debounce** | `array-contains-any` + client-side substring filter |
| **Board page size** | **20 / cursor pagination** | `startAfterDocument` + `limit(20)` |

## Architecture (Summary)

```mermaid
graph TD
    subgraph Client
        A[Flutter App<br/>Android / iOS]
        B[Next.js Admin<br/>TypeScript + Tailwind]
    end

    subgraph Firebase
        C[Auth<br/>Google / Apple / Kakao / GitHub]
        D[Firestore<br/>realtime DB]
        E[Storage<br/>images / profiles]
        F[FCM<br/>push notifications]
        G[Crashlytics<br/>crash monitoring]
    end

    subgraph Server
        H[Cloud Functions<br/>Node.js]
        I[Scheduler<br/>unsuspension check]
    end

    J[NEIS API<br/>meals / timetable / academic calendar]

    A <-->|Riverpod state| D
    A <--> C
    A <--> E
    A --> G
    A <-->|realtime stream| F
    A <-->|REST API| J

    B <-->|shared Firestore| D

    H -->|comment / chat / account events| F
    H <-->|Firestore triggers| D
    H <-->|Kakao OAuth| C
    I -->|hourly suspension expiry| D
```

- **Riverpod provider dependency graph** and **layered data-flow model** → [architecture-overview_en.md](./docs/architecture-overview_en.md)
- Storage allocation rationale (sqflite / Firestore / SecureStorage / Cloud Storage) → [ADR-06](./docs/architecture-decisions_en.md)

### 🔗 [Interactive Riverpod Graph (GitHub Pages)](https://monkshark.github.io/hansol_hs_flutter_app/riverpod_graph.html)

D3.js-based zoom/drag graph. Source HTML at `docs/riverpod_graph.html`.

## Architecture Decisions (Summary)

| ADR | Decision | Link |
|---|---|---|
| 01 | State mgmt = Riverpod 2.5 | [link](./docs/architecture-decisions_en.md#adr-01-state-management-riverpod-25) |
| 02 | Grade storage = flutter_secure_storage (local-only) | [link](./docs/architecture-decisions_en.md#adr-02-sensitive-data-storage-flutter_secure_storage) |
| 03 | Board search = client-side n-gram index | [link](./docs/architecture-decisions_en.md#adr-03-board-search-client-side-n-gram-indexing) |
| 04 | Like counter = `Map<uid,bool>` + denormalized int | [link](./docs/architecture-decisions_en.md#adr-04-like-counter-mapuidbool--denormalized-int) |
| 05 | Charts = direct `CustomPainter` | [link](./docs/architecture-decisions_en.md#adr-05-charts-custompainter-directly) |
| 06 | Storage allocation = SQLite/Firestore/SecureStorage/Cloud Storage | [link](./docs/architecture-decisions_en.md#adr-06-storage-allocation) |
| 07 | DI = GetIt + abstract repository | [link](./docs/architecture-decisions_en.md#adr-07-di-getit--abstract-repository) |
| 08 | Test strategy = 4 layers (Unit/Provider/Widget/Rules) | [link](./docs/architecture-decisions_en.md#adr-08-test-strategy-unit--provider--widget--rules) |

Full details → [architecture-decisions_en.md](./docs/architecture-decisions_en.md).

## Tech Stack

| Category | Tech |
|---|---|
| **Mobile** | Flutter (Dart) — Android / iOS |
| **State** | Riverpod 2.5 — AsyncNotifier / Notifier |
| **DI** | GetIt + abstract repository — mockable |
| **Admin Web** | Next.js 14 — App Router, TypeScript, Tailwind |
| **Backend** | Firebase — Auth, Firestore, Storage, FCM, Crashlytics |
| **Server** | Cloud Functions (Node.js) — push, Kakao OAuth, scheduler |
| **External API** | NEIS public data — meals, timetable, academic calendar |
| **Local** | sqflite (schedule DB), SharedPreferences (settings/cache) |
| **Auth** | Google / Apple / Kakao / GitHub OAuth |
| **CI** | GitHub Actions — analyze + test + Codecov + Android APK |
| **Test** | `flutter_test` — Unit + Widget + Provider (146) + Firestore rules (34) |

## Features (Summary)

| Category | Highlights | Deep dive |
|---|---|---|
| **Public** | Meals, timetable, academic calendar, urgent popup, home widgets (Android/iOS), offline | [public-features_en.md](./docs/features/public-features_en.md) |
| **Community** | Board (6 categories + popular + n-gram search), 1:1 chat, notifications, feedback | [community-features_en.md](./docs/features/community-features_en.md) |
| **Personal** | Grades (susi/jeongsi, local-only), schedules, D-day, profile | [personal-features_en.md](./docs/features/personal-features_en.md) |
| **Admin** | Flutter admin + Next.js Admin Web, approval/suspension/report/feedback/audit logs | [admin-features_en.md](./docs/features/admin-features_en.md) |

## Security & Privacy

- **Firestore rules**: role-based access control + per-field update validation + `validCounterDelta(±1)`
- **Grades stay local**: `flutter_secure_storage` → Android Keystore / iOS Keychain. Never uploaded.
- **Rate limiting**: 30s post cooldown, 10s comment cooldown, duplicate-report index.
- **On deletion**: Firestore → Storage → Auth order for complete erasure.
- **OAuth only**: no passwords stored.

Details → [security_en.md](./docs/security_en.md).

## Testing & CI/CD

- **180 tests** (Unit 89 + Provider 17 + Widget 17 + Golden 5 + Repository 8 + Rules 34 + Integration 10)
- `flutter test --coverage` ~3s / `firebase emulators:exec ... npm test` ~4s
- Two GitHub Actions workflows: [flutter.yml](./.github/workflows/flutter.yml), [firestore-rules.yml](./.github/workflows/firestore-rules.yml)
- Codecov upload, debug APK artifact on master push

Details → [testing_en.md](./docs/testing_en.md), [cicd-setup_en.md](./docs/cicd-setup_en.md).

## Data Model (Summary)

```mermaid
erDiagram
    users ||--o{ posts : "authors"
    users ||--o{ notifications : "receives"
    posts ||--o{ comments : "contains"
    posts ||--o{ reports : "reported by"
    chats ||--o{ messages : "contains"
    users }o--o{ chats : "participates"
```

Collection schema, indexes, and rule mappings → [data-model_en.md](./docs/data-model_en.md).

## Technical Challenges (Highlights)

3 picks from 14 real production cases:

<details>
<summary><b>Admin screen Firestore reads: 130 → 20–30</b></summary>

Swapped `StreamBuilder` for `FutureBuilder` + collapsed `ExpansionTile` child lazy render. Closed tabs do 0 reads.

→ [technical-challenges_en.md#9](./docs/technical-challenges_en.md#9-admin-screen-firestore-read-overload-stream--future-transition)
</details>

<details>
<summary><b>StatefulWidget 1,400+ lines → Stateless composition (-43%)</b></summary>

Four large screens 4,575 → 2,589 lines, 15 widget modules extracted, 113 tests still green.

→ [technical-challenges_en.md#13](./docs/technical-challenges_en.md#13-statefulwidget-1400-lines--stateless-composition-refactoring)
</details>

<details>
<summary><b>Riverpod AsyncNotifier <code>invalidateSelf</code> race</b></summary>

Async `ref.invalidateSelf()` made provider tests flaky. Fixed by replacing state directly in mutators.

→ [technical-challenges_en.md#11](./docs/technical-challenges_en.md#11-riverpod-asyncnotifier-race-condition-invalidateself)
</details>

**All 14 cases** → [technical-challenges_en.md](./docs/technical-challenges_en.md)

## License

Published for learning and portfolio purposes. School logos and image assets may not be reused.

## Contact

- Bugs / feature requests: GitHub Issues
- In-app: Settings → Feedback / bug report
