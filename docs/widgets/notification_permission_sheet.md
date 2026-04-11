# NotificationPermissionSheet

> `lib/widgets/notification_permission_sheet.dart` — 알림 권한 요청 바텀시트

온보딩 완료 시, 또는 알림 설정에서 권한이 거부된 상태에서 토글 시도 시 표시되는 바텀시트

---

## `show`

```dart
static Future<bool> show(BuildContext context, {bool openSettings = false})
```

**설명**: 알림 권한 요청 바텀시트를 표시함

### 파라미터

| 파라미터 | 설명 |
|----------|------|
| `openSettings` | `false` (기본): OS 권한 팝업 요청. `true`: `openAppSettings()`로 설정 앱 이동 |

### 반환값

| 값 | 의미 |
|----|------|
| `true` | 사용자가 "허용" / "설정으로 이동" 탭 |
| `false` | 사용자가 "나중에" 탭 또는 바텀시트 닫음 |

### 사용처

| 호출 위치 | `openSettings` | 시점 |
|-----------|----------------|------|
| `OnboardingScreen._finish()` | `false` | 온보딩 완료 직후, OS 권한 팝업 요청 |
| `NotificationSettingScreen._ensurePermission()` | `true` | 권한 거부 상태에서 토글 시도 시, 설정 앱으로 이동 |

---

## 바텀시트 구성

| 요소 | 내용 |
|------|------|
| 아이콘 | `Icons.notifications_active_rounded` (primaryColor) |
| 제목 | "알림 허용" |
| 설명 (기본) | "알림을 허용하면 급식 메뉴 등 다양한 알림을 받을 수 있어요" |
| 설명 (설정 모드) | "알림을 받으려면 설정에서 알림 권한을 허용해 주세요" |
| 주요 버튼 | "허용" / "설정으로 이동" |
| 보조 버튼 | "나중에" |
