# NetworkStatus

> `lib/network/network_status.dart` — 네트워크 연결 상태

`connectivity_plus` 플러그인으로 현재 연결 상태를 확인함. 일회성 체크와 실시간 스트림 모두 제공

---

## `isUnconnected`

```dart
static Future<bool> isUnconnected()
```

**설명**: WiFi/모바일 데이터 미연결 시 `true`를 반환함

```dart
if (_testOverride != null) return _testOverride!();
final results = await Connectivity().checkConnectivity();
return results.isEmpty || results.contains(ConnectivityResult.none);
```

- `results`가 비어있거나 `none`을 포함하면 오프라인
- API 호출 전 오프라인 체크에 사용 ([MealDataApi](../api/meal_data_api.md), [TimetableDataApi](../api/timetable_data_api.md), [NoticeDataApi](../api/notice_data_api.md))
- 오프라인이면 캐시 데이터 반환 또는 안내 메시지 표시

---

## 실시간 스트림 모니터링

### `onStatusChange`

```dart
static Stream<bool> get onStatusChange
```

연결 상태 변경 스트림. `true` = 오프라인, `false` = 온라인.
최초 접근 시 자동으로 `connectivity_plus` 리스닝 시작. 브로드캐스트 스트림이므로 여러 위젯에서 동시 구독 가능

사용처:
- `OfflineBanner` — 오프라인 배너 + 동기화 상태 표시
- `OfflineQueueManager` — 네트워크 복원 시 큐 자동 처리

### `isOffline`

```dart
static bool get isOffline
```

마지막으로 알려진 연결 상태. 스트림 구독 없이 현재 상태를 동기적으로 확인할 때 사용

---

## 테스트 지원

```dart
static Future<bool> Function()? _testOverride;

@visibleForTesting
static set testOverride(Future<bool> Function()? fn) => _testOverride = fn;

@visibleForTesting
static void resetStream()
```

- `testOverride`로 `connectivity_plus` 플러그인 없이 온/오프라인 시나리오 테스트
- `resetStream()`으로 스트림 상태 초기화 (테스트 간 격리)
- 기본값 `null` → 프로덕션에서는 실제 `Connectivity()` 경로 실행
