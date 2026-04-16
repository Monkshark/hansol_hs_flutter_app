# Product Overview

> 한국어: [product-overview.md](./product-overview.md)

## One-Liner

**An integrated school platform for students, teachers, alumni, and parents of Hansol High School (Sejong, Korea).** Built on a Flutter mobile app + Next.js admin dashboard with NEIS public-data API integration, Firebase realtime database, role-based access control, push notifications, and 1:1 chat — at production-service quality.

## Why This Exists

School announcements, meals, timetables, and academic calendars are scattered across different websites and notification channels. This app unifies them **in one user context**, and adds a student community layer (board / chat) to consolidate school communication.

**Grade management** stays strictly local to protect student privacy, while still offering trend charts and per-subject goal management.

## Audience

| Audience | Value |
|---|---|
| **Students** | Meals / timetable / academic calendar / board / chat / grades / personal schedule / home widget |
| **Teachers** | Teacher-view timetable, announcements, approvals/moderation |
| **Alumni** | Login + community access (grade/timetable limited) |
| **Parents** | Academic calendar / announcements / urgent popup subscription |
| **Admins (manager/admin)** | Flutter Admin screen + Next.js Admin Web |

## Core Value Props

- **Everything school-related in one app** — meals, timetable, schedule, community, grades
- **Student privacy first** — grades stored locally only, OAuth-only auth
- **Realtime** — Firestore onSnapshot + FCM push
- **Offline-friendly** — meal/timetable cache, offline banner, sqflite personal schedule
- **Low-cost ops** — $0–3 / month at ~1,000 users (free tier)

## Scope Boundaries (Explicit Non-Goals)

- **Grades are not backed up or synced** — device change loses data (intentional)
- **No school-internal system integration** — only NEIS public API
- **No web version** — Admin dashboard is web, end users are app-only
- **No payments / paid features**

## Scale Numbers

| Item | Value |
|---|---|
| Total LOC | ~40,000 (Dart 33,389 + TS 2,098 + Java/XML 1,181 + Swift 330 + JS 543) |
| Source files | 122 (Flutter) + 22 (Admin Web TS/TSX) + Android/iOS widgets |
| Cloud Functions | 13 |
| OAuth providers | 4 (Google / Apple / Kakao / GitHub) |
| Push types | 4 FCM (`account` / `comment` / `new_post` / `chat`) + 3 local (breakfast/lunch/dinner) |
| Tests | 513 Flutter + 34 Rules = 547 |

## Tech Stack Summary

| Category | Tech |
|---|---|
| Mobile | Flutter (Dart) — Android / iOS |
| State | Riverpod 2.5 |
| DI | GetIt + abstract repository |
| Admin Web | Next.js 14 + TypeScript + Tailwind |
| Backend | Firebase (Auth / Firestore / Storage / FCM / Crashlytics) |
| Server | Cloud Functions (Node.js) |
| External | NEIS public-data API |

Details → [architecture-overview_en.md](./architecture-overview_en.md).

## Main Flows

1. **OAuth login → identity → admin approval → home** ([account-and-access_en.md](./account-and-access_en.md))
2. **Home shows meal / timetable / schedule** ([public-features_en.md](../features/public-features_en.md))
3. **Board / chat for community** ([community-features_en.md](../features/community-features_en.md))
4. **Grades / personal schedule managed locally** ([personal-features_en.md](../features/personal-features_en.md))
5. **Admins manage users / content on Admin Web** ([admin-features_en.md](../features/admin-features_en.md))

## See Also
- [Architecture Overview](./architecture-overview_en.md)
- [Architecture Decisions](./architecture-decisions_en.md)
- [Contributing Guide](../CONTRIBUTING_en.md)
- [Deployment Guide](../DEPLOY_en.md)
- [User Guide](../USER_GUIDE_en.md)
