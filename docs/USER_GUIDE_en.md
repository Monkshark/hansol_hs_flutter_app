# User Guide

> 한국어: [USER_GUIDE.md](./USER_GUIDE.md)

How to use the Hansol HS app, organized by role (student, teacher, alumni, parent). New users should start with "Getting Started"; jump to "Main Features" if you already know the basics.

## Getting Started

### 1. Install
- Android: Play Store → search "한솔고등학교"
- iOS: App Store → search "한솔고등학교"
- Versions below the minimum prompt a mandatory update on launch.

### 2. Sign In
Pick any of the four providers:
- Google
- Apple (iOS)
- Kakao
- GitHub

No passwords — social login only.

### 3. Pick an Identity & Fill Your Profile
- Choose student / alumni / teacher / parent
- Students/teachers also enter year/class/number
- Real names preferred (school context)

### 4. Wait for Approval
Most features unlock only after admin approval. Usually within a day.

## Features by Role

| Feature | Student | Teacher | Alumni | Parent |
|---|:---:|:---:|:---:|:---:|
| Meals / academic calendar | ✅ | ✅ | ✅ | ✅ |
| Timetable (your class) | ✅ | ✅ (teacher view) | ❌ | ❌ |
| Board / chat | ✅ | ✅ | ✅ | partial |
| Grades (local) | ✅ | ❌ | ✅ | ❌ |
| Personal schedule / D-day | ✅ | ✅ | ✅ | ✅ |
| Create announcements | ❌ | ✅ | ❌ | ❌ |
| Home widgets | ✅ | ✅ | partial | partial |

## Main Features

### Home
- Today's meal, timetable, and calendar in one screen
- Scroll up for D-day and personal schedules
- Tap the bell (top-right) for in-app notifications

### Meals
- Breakfast / lunch / dinner tabs
- Tap a menu → nutrition + allergen info
- Save as image or share externally (KakaoTalk, etc.)

### Timetable
- Based on your class or your selected electives
- Current period is highlighted automatically
- Long-press a subject to customize its color

### Schedule
- Swipe left/right on the month calendar
- Tap an empty date → add a personal event
- Multi-day events render as a continuous colored bar

### Board
- 6 categories + Popular tab
- Attach images / polls / schedules when writing
- Anonymous posts get a post-scoped anonymous number
- Search supports recent keywords + n-gram matching

### Chat
- Top-right "New chat" → search for a user
- Long-press a message for the delete menu
- Unread messages show a badge

### Grades
- Susi / Jeongsi tabs
- Enter scores per subject → auto-convert to grade / percentile
- Trend chart modes: grade / raw / percentile / standard score
- **Grades live on this device only.** They don't transfer when you change devices.

### Personal Schedule & D-day
- 6 default colors + a circular color picker
- D-day items can be pinned to the home screen

### Notifications
Five independent toggles:
- Comments / replies
- Chat
- New posts (subscribed categories)
- Account (approval / suspension / role change)
- Meals (local notification, schedulable time)

### Home Widgets
- **Android**: 4×2 meal / 3×2 timetable / 5×2 combined
- **iOS**: Medium meal / Medium timetable / Large combined
- Auto-refresh at midnight and on app launch

## For Admins

Privileged roles get extra functionality:
- **moderator** — handle reports, hide posts/comments (no suspension)
- **auditor** — read-only access to all reports / logs / stats (teacher audit role)
- **manager** — suspend, pin notices, approve users
- **admin** — everything + change other users' roles

Tools:
- **Flutter Admin screen**: Settings → Admin
- **Admin Web**: separate web dashboard (URL provided by ops) — sidebar items auto-filter by role

Details → [docs/features/admin-features_en.md](https://monkshark.github.io/hansol_hs_flutter_app/#features/admin-features_en.md).

## Account Management

### Suspension
- While suspended: read-only (no posts/comments/chats)
- Expiry auto-cleared every hour
- Release triggers a push notification

### Role Changes
- Request from an admin if you need student-council / broadcasting privileges
- Admin changes `role` to `moderator` / `auditor` / `manager` / `admin`
- The app refreshes the ID token automatically right after the change, so the new role takes effect immediately

### New School Year Update
- Students/teachers see a popup in March to update year/class/number
- Identity (student/teacher/etc.) can only be changed by an admin

### Deletion
- Settings → Account → Delete account
- Double-confirm, then immediate wipe:
  - profile / posts / comments / chats / local grades / profile picture
- Re-signing in with the same social account later counts as a new user

## FAQ

**Q. Can I see my grades on another device?**
A. No. Grades live only in this device's OS-secured storage — they don't upload. You'll re-enter them on a new device.

**Q. My Kakao login shows a different profile picture.**
A. We pull the Kakao picture as-is. Replace it in Settings → My account → profile picture.

**Q. I'm not getting notifications.**
A. Check Settings → Notifications for the category, and system-level notification permission. Some notifications are suppressed during suspension.

**Q. Do meals / timetable work offline?**
A. Previously fetched data is cached and visible offline. A red offline banner shows at the top.

**Q. My widget isn't updating.**
A. Open the app once. Automatic refresh runs at midnight + hourly (iOS) / via AlarmManager (Android).

**Q. Can I pin my own post as an announcement?**
A. Only managers/admins can pin. Moderators can handle reports / hide content; auditors are read-only.

**Q. Can I appeal a moderation decision (e.g., a suspension)?**
A. Settings → Appeals. You have 90 days to submit a reason (PIPA right). You'll get a push notification once an admin reviews it.

**Q. Can I download a copy of all my data?**
A. Settings → Data Request. Your posts / comments / report history / chats are bundled into a JSON file with a download link sent to your email. The link expires after 30 days.

**Q. Can anyone see who wrote an anonymous post?**
A. Regular users see only the anonymous number. Admins can reveal identity for moderation — every lookup is logged in `admin_logs`.

## Contact

Use the in-app Feedback / Bug report menu — admins will see it. For anything urgent, go through the school's official channel.

## Related Docs
- [Public Features](https://monkshark.github.io/hansol_hs_flutter_app/#features/public-features_en.md)
- [Community Features](https://monkshark.github.io/hansol_hs_flutter_app/#features/community-features_en.md)
- [Personal Features](https://monkshark.github.io/hansol_hs_flutter_app/#features/personal-features_en.md)
- [Account & Access](https://monkshark.github.io/hansol_hs_flutter_app/#guides/account-and-access_en.md)
