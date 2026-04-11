# UpdateChecker

> `lib/notification/update_checker.dart` — Firestore 기반 앱 버전 체크

---

## `check`

```dart
static Future<void> check(BuildContext context)
```

**설명**: 앱 버전을 체크하고 업데이트 다이얼로그를 표시함. `MainScreen.initState`에서 호출

1. Firestore에서 버전 정보 조회:
   ```dart
   final doc = await FirebaseFirestore.instance
       .collection('app_config').doc('version').get();
   ```

2. 현재 앱 버전 확인:
   ```dart
   final packageInfo = await PackageInfo.fromPlatform();
   final currentVersion = packageInfo.version;
   ```

3. 버전 비교:
   ```dart
   final forceUpdate = _compareVersions(currentVersion, minVersion) < 0;   // 최소 버전 미만
   final optionalUpdate = _compareVersions(currentVersion, latestVersion) < 0;  // 최신 미만
   ```

4. 다이얼로그 분기:
   - **필수 업데이트** (`forceUpdate`): 닫기 불가 (`PopScope.canPop: false`), "업데이트"만 가능
   - **선택 업데이트** (`optionalUpdate`): "업데이트" + "나중에" 버튼

5. 업데이트 버튼 탭 시 스토어 URL로 이동:
   ```dart
   launchUrl(Uri.parse(updateUrl), mode: LaunchMode.externalApplication);
   ```

6. 플랫폼별 URL 분기:
   ```dart
   final updateUrl = (isIOS ? data['updateUrlIOS'] : data['updateUrlAndroid'])
       ?? data['updateUrl'] ?? '';
   ```

---

## `_compareVersions`

```dart
static int _compareVersions(String a, String b)
```

**설명**: 시맨틱 버전을 비교함 (major.minor.patch)

```dart
final aParts = a.split('.').map(int.parse).toList();
final bParts = b.split('.').map(int.parse).toList();
// 왼쪽부터 비교, a < b → -1, a > b → 1, 같으면 0
```

빈 문자열이면 0 반환 (비교 건너뜀)

---

## Firestore 문서 구조 (`app_config/version`)

| 필드 | 타입 | 설명 |
|------|------|------|
| `latest` | String | 최신 버전 (예: `'2.1.0'`) |
| `min` | String | 최소 지원 버전 (이 미만이면 필수 업데이트) |
| `updateUrl` | String | 기본 스토어 URL |
| `updateUrlAndroid` | String? | Android 전용 URL |
| `updateUrlIOS` | String? | iOS 전용 URL |
| `message` | String | 업데이트 안내 메시지 |
