# Public Features (Meals / Timetable / Schedule / Widgets / Announcements)

> 한국어: [public-features.md](./public-features.md)

Core information features any user encounters. Some require login, but they all fall under "public information" in spirit.

## Meals

- **NEIS API**-based real-time breakfast/lunch/dinner lookup
- **Monthly prefetch** cache (24h / 5min for empty results); Completer pattern avoids concurrent duplicate fetches ([Technical Challenge #2](../guides/technical-challenges_en.md#2-meal-api-concurrent-request-race-condition))
- Tap a meal card → share as image; shows **nutrition** (carb/protein/fat) + allergen info
- Meal notifications include a menu preview (local notifications, per-meal schedulable)

**Files**: `lib/screens/main/meal_screen.dart`, `lib/api/meal_data_api.dart`, `test/meal_api_test.dart`, `test/meal_test.dart`

### Cache Strategy

| Case | TTL |
|---|---|
| Success response | 24 hours |
| Empty (weekend/break) | 5 minutes (avoid over-refetching) |
| Error | expire immediately, retry on next access |

## Timetable

- **1st year**: auto by class. **2nd/3rd year**: custom based on selected electives
- **Teacher view**: year tabs (1/2/3) → swipe subjects → pick among duplicated classes
- **Auto slot-conflict detection** + resolution dialog; per-subject color customization ([Technical Challenge #4](../guides/technical-challenges_en.md#4-timetable-elective-slot-conflicts))
- **Current period** live highlight (1-min refresh, progress bar); today's column highlighted
- Elective save confirmation + unsaved back-nav warning
- Auto-reset in March (new semester) for timetable + electives

**Files**: `lib/screens/sub/timetable_view_screen.dart`, `timetable_select_screen.dart`, `teacher_timetable_select_screen.dart`, `test/timetable_api_test.dart`

## Academic & Personal Schedule

- **Custom monthly calendar** (swipe to change months, variable week count, Korean locale)
- **Continuous academic-event bar** (unbroken colored bar + event name)
- **Personal events** single/multi-day, **6 presets + circular color picker** (with brightness)
- **NEIS academic events** shown automatically; personal events as colored dots
- **D-day** management + home-screen pinning

**Storage**: personal events in `sqflite` (local). Academic events cached from NEIS.

**Files**: `lib/screens/main/home_screen.dart` (calendar widget), `lib/screens/sub/dday_screen.dart`, `test/schedule_data_test.dart`, `test/dday_manager_test.dart`

## Android Home Widgets

- **Meal widget (4×2)**: today's breakfast/lunch/dinner
- **Timetable widget (3×2)**: today's schedule, current period highlighted
- **Combined widget (5×2)**: meal + timetable together
- System dark/light mode auto-matched
- **Auto-refresh at midnight** (AlarmManager + Dart background callback)
- Refresh on app launch; **0 Firestore reads** (uses cached data)

**Files**: `android/app/src/main/java/.../widget/`, Flutter ↔ native bridge via `home_widget`.

## iOS Home Widgets

- **Meal widget (Medium)**: today's breakfast/lunch/dinner
- **Timetable widget (Medium)**: today's schedule, current period highlighted
- **Combined widget (Large)**: meal + timetable together
- **SwiftUI + WidgetKit** native implementation
- App Groups for Flutter ↔ widget data sharing
- System dark/light auto-matched
- Hourly Timeline refresh

**Files**: `ios/Widget*/`. App Groups setup in [DEPLOY_en.md](../../DEPLOY_en.md).

## Urgent Popup Announcements

- Modal popup shown on app launch for high-priority news
- **3 types**: urgent (red), notice (blue), event (green)
- **Start/end dates** — automatically dormant outside the window
- **"Hide for today"** supported (admin can disable)
- Authored via Flutter Admin screen + Admin Web

**Storage**: `app_config/announcement` (Firestore). See [admin-features_en.md](./admin-features_en.md).

## App Update & Offline

- **Update checker**: compares Firestore `app_config/version` against the installed version
  - **Mandatory**: non-dismissible dialog + store link
  - **Optional**: dialog with "Later"
  - Version comparison over `major.minor.patch`
- **Offline banner**: red "offline" banner at top when network drops, auto-dismiss on reconnect
- **Offline cache**: meals/timetable visible offline via local cache

**Files**: `lib/main.dart` (startup check), `lib/data/setting_data.dart`, connectivity via `connectivity_plus`.

## Announcements List

- School announcements section (`lib/screens/main/notice_screen.dart`)
- Admin-authored official notices (separate from board)
- Attachments / importance flag supported

## See Also
- [User Guide](../../USER_GUIDE_en.md)
- [Community Features](./community-features_en.md)
- [Personal Features](./personal-features_en.md)
- [Data Model](../guides/data-model_en.md) — `app_config`, `users` schema
