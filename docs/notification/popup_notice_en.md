# PopupNotice

> 한국어: [popup_notice.md](./popup_notice.md)

> `lib/notification/popup_notice.dart` — In-app popup notices

Emergency/event popup based on the Firestore `app_config/popup` document.

---

## `check`

```dart
static Future<void> check(BuildContext context)
```

**Description**: Displays a dialog if an active popup exists. Called from `MainScreen.initState`.

1. Fetch the popup config from Firestore:
   ```dart
   final doc = await FirebaseFirestore.instance
       .collection('app_config').doc('popup').get();
   if (data['active'] != true) return;
   ```

2. Date-range check (`startDate` ~ `endDate`):
   ```dart
   if (startDate.isNotEmpty && todayStr.compareTo(startDate) < 0) return;
   if (endDate.isNotEmpty && todayStr.compareTo(endDate) > 0) return;
   ```

3. "Don't show today" check:
   ```dart
   final dismissKey = 'popup_dismissed_$todayStr';
   if (prefs.getBool(dismissKey) == true) return;
   ```

4. Determine color/icon by type:
   ```dart
   'emergency' → Colors.red + Icons.warning_amber_rounded
   'event'     → Color(0xFF4CAF50) + Icons.celebration
   'notice'    → AppColors.theme.primaryColor + Icons.campaign
   ```

5. Display the dialog:
   - **Mandatory popup** (`dismissible: false`): cannot be dismissed, only "Confirm" available
   - **Regular popup** (`dismissible: true`): Confirm + "Don't show today" button

6. When "Don't show today" is tapped:
   ```dart
   prefs.setBool(dismissKey, true);  // saved with today's key
   ```

---

## Firestore document structure (`app_config/popup`)

| Field | Type | Description |
|-------|------|-------------|
| `active` | bool | Whether the popup is active |
| `title` | String | Popup title |
| `content` | String | Popup body |
| `type` | String | `'emergency'` / `'event'` / `'notice'` |
| `startDate` | String | Start date (`'2026-04-01'`) |
| `endDate` | String | End date |
| `dismissible` | bool | Whether it can be dismissed |
