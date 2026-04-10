# NetworkStatus

> `lib/network/network_status.dart` — 네트워크 연결 상태

`connectivity_plus` 플러그인으로 현재 연결 상태를 확인한다.

---

## `isUnconnected`

```dart
static Future<bool> isUnconnected()
```

**설명**: WiFi/모바일 데이터 미연결 시 `true`를 반환한다.

```dart
final results = await Connectivity().checkConnectivity();
return results.isEmpty || results.contains(ConnectivityResult.none);
```

- `results`가 비어있거나 `none`을 포함하면 오프라인
- API 호출 전 오프라인 체크에 사용 (MealDataApi, TimetableDataApi, NoticeDataApi)
- 오프라인이면 캐시 데이터 반환 또는 안내 메시지 표시
