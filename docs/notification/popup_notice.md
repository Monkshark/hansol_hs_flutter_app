# PopupNotice

> `lib/notification/popup_notice.dart` — 인앱 팝업 공지

Firestore `app_config/popup` 문서 기반 긴급/이벤트 팝업

---

## `check`

```dart
static Future<void> check(BuildContext context)
```

**설명**: 활성 팝업이 있으면 다이얼로그를 표시한다. `MainScreen.initState`에서 호출

1. Firestore에서 팝업 설정 조회:
   ```dart
   final doc = await FirebaseFirestore.instance
       .collection('app_config').doc('popup').get();
   if (data['active'] != true) return;
   ```

2. 날짜 범위 체크 (`startDate` ~ `endDate`):
   ```dart
   if (startDate.isNotEmpty && todayStr.compareTo(startDate) < 0) return;
   if (endDate.isNotEmpty && todayStr.compareTo(endDate) > 0) return;
   ```

3. "오늘 안 보기" 체크:
   ```dart
   final dismissKey = 'popup_dismissed_$todayStr';
   if (prefs.getBool(dismissKey) == true) return;
   ```

4. 타입별 색상/아이콘 결정:
   ```dart
   'emergency' → Colors.red + Icons.warning_amber_rounded
   'event'     → Color(0xFF4CAF50) + Icons.celebration
   'notice'    → AppColors.theme.primaryColor + Icons.campaign
   ```

5. 다이얼로그 표시:
   - **필수 팝업** (`dismissible: false`): 닫기 불가, 확인만 가능
   - **일반 팝업** (`dismissible: true`): 확인 + "오늘 하루 안 보기" 버튼

6. "오늘 하루 안 보기" 탭 시:
   ```dart
   prefs.setBool(dismissKey, true);  // 당일 키로 저장
   ```

---

## Firestore 문서 구조 (`app_config/popup`)

| 필드 | 타입 | 설명 |
|------|------|------|
| `active` | bool | 팝업 활성화 여부 |
| `title` | String | 팝업 제목 |
| `content` | String | 팝업 본문 |
| `type` | String | `'emergency'` / `'event'` / `'notice'` |
| `startDate` | String | 시작일 (`'2026-04-01'`) |
| `endDate` | String | 종료일 |
| `dismissible` | bool | 닫기 가능 여부 |
