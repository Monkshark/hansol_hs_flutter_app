# API Reference - Table of Contents

> 한국어: [README.md](./README.md)
>
> Screen and Widget documentation is excluded. Only core layers (services, models, APIs, notifications, etc.) are organized here.
>
> For topic-based guides (architecture, data models, tests, security, etc.), see [`guides/`](./guides/). For feature-level details, see [`features/`](./features/).

## App Entry Point
- [main](main_en.md) — App initialization, MainScreen, global state

## API Layer (lib/api/)
- [meal_data_api](api/meal_data_api_en.md) — NEIS meal API, monthly prefetch, 24h/5min cache
- [notice_data_api](api/notice_data_api_en.md) — NEIS school schedule API, upcoming events, 12h cache
- [timetable_data_api](api/timetable_data_api_en.md) — NEIS timetable API, subject combinations, 12h cache

## Data Layer (lib/data/)
- [auth_service](data/auth_service_en.md) — 4 social login providers, profile CRUD, 5-minute cache
- [auth_repository](data/auth_repository_en.md) — AuthRepository interface, GetIt DI
- [grade_manager](data/grade_manager_en.md) — Grade CRUD, goal management, grade conversion
- [grade_repository](data/grade_repository_en.md) — GradeRepository interface, GetIt DI
- [dday_manager](data/dday_manager_en.md) — D-day CRUD, Firestore sync
- [local_database](data/local_database_en.md) — SQLite schedule DB, Firestore sync
- [subject_data_manager](data/subject_data_manager_en.md) — Elective subject load/save
- [search_tokens](data/search_tokens_en.md) — Korean 2-gram tokenization
- [search_history_service](data/search_history_service_en.md) — Search history (up to 10 entries)
- [secure_storage_service](data/secure_storage_service_en.md) — Encrypted storage wrapper
- [analytics_service](data/analytics_service_en.md) — Firebase Analytics event wrapper
- [setting_data](data/setting_data_en.md) — SharedPreferences settings singleton
- [service_locator](data/service_locator_en.md) — GetIt DI setup
- [meal](data/meal_en.md) — Meal data model (freezed)
- [schedule_data](data/schedule_data_en.md) — Schedule data model
- [subject](data/subject_en.md) — Subject data model (freezed)
- [device](data/device_en.md) — Device size calculation utility
- [api_strings](data/api_strings_en.md) — API sentinel string constants (for determining data presence)
- [board_categories](data/board_categories_en.md) — Board category constants + l10n/color/FCM topic helpers
- [post_repository](data/post_repository_en.md) — Board Firestore CRUD singleton

## Notifications (lib/notification/)
- [fcm_service](notification/fcm_service_en.md) — FCM push notifications, topics, deep links
- [daily_meal_notification](notification/daily_meal_notification_en.md) — Local meal notification scheduling
- [popup_notice](notification/popup_notice_en.md) — In-app popup notices
- [update_checker](notification/update_checker_en.md) — App version check

## State Management (lib/providers/)
- [providers](providers/providers_en.md) — All Riverpod Notifier/AsyncNotifier definitions

## Styles (lib/styles/)
- [app_colors](styles/app_colors_en.md) — Theme colors + AnimatedAppColors
- [dark_app_colors](styles/dark_app_colors_en.md) — Dark theme color implementation
- [light_app_colors](styles/light_app_colors_en.md) — Light theme color implementation

## Network (lib/network/)
- [network_status](network/network_status_en.md) — Network connection status stream
- [offline_queue_manager](network/offline_queue_manager_en.md) — Offline write queue (sqflite)
