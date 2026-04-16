# UpdateChecker

> 한국어: [update_checker.md](./update_checker.md)

> `lib/notification/update_checker.dart` — Firestore-based app version check

---

## `check`

```dart
static Future<void> check(BuildContext context)
```

**Description**: Checks the app version and displays an update dialog. Called from `MainScreen.initState`.

1. Fetch version info from Firestore:
   ```dart
   final doc = await FirebaseFirestore.instance
       .collection('app_config').doc('version').get();
   ```

2. Check the current app version:
   ```dart
   final packageInfo = await PackageInfo.fromPlatform();
   final currentVersion = packageInfo.version;
   ```

3. Version comparison:
   ```dart
   final forceUpdate = _compareVersions(currentVersion, minVersion) < 0;   // below minimum
   final optionalUpdate = _compareVersions(currentVersion, latestVersion) < 0;  // below latest
   ```

4. Dialog branching:
   - **Forced update** (`forceUpdate`): cannot be dismissed (`PopScope.canPop: false`), only "Update" available
   - **Optional update** (`optionalUpdate`): "Update" + "Later" buttons

5. When the Update button is tapped, open the store URL:
   ```dart
   launchUrl(Uri.parse(updateUrl), mode: LaunchMode.externalApplication);
   ```

6. Per-platform URL branching:
   ```dart
   final updateUrl = (isIOS ? data['updateUrlIOS'] : data['updateUrlAndroid'])
       ?? data['updateUrl'] ?? '';
   ```

---

## `_compareVersions`

```dart
static int _compareVersions(String a, String b)
```

**Description**: Compares semantic versions (major.minor.patch).

```dart
final aParts = a.split('.').map(int.parse).toList();
final bParts = b.split('.').map(int.parse).toList();
// Compare from the left: a < b → -1, a > b → 1, equal → 0
```

Returns 0 for an empty string (comparison skipped).

---

## Firestore document structure (`app_config/version`)

| Field | Type | Description |
|-------|------|-------------|
| `latest` | String | Latest version (e.g., `'2.1.0'`) |
| `min` | String | Minimum supported version (below this → forced update) |
| `updateUrl` | String | Default store URL |
| `updateUrlAndroid` | String? | Android-specific URL |
| `updateUrlIOS` | String? | iOS-specific URL |
| `message` | String | Update notice message |
