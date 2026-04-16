# Exceptions

> `lib/data/exceptions.dart` — 커스텀 예외 클래스 계층

---

## 클래스 계층

```
Exception
└── AppException (base)
    ├── NetworkException — HTTP 타임아웃, 연결 실패
    ├── ApiException — API 응답 파싱 실패, 비정상 응답
    └── AuthException — 인증/권한 관련 에러
```

모든 예외 클래스는 `message` (설명)와 `cause` (원본 에러, 선택)를 가짐

---

## 사용 패턴

### API 레이어 (`_fetchData`)

```dart
// 최하위 HTTP 호출 — 실패 시 NetworkException throw
static Future<Map<String, dynamic>> _fetchData(String url) async {
  try {
    final response = await _client.get(Uri.parse(url)).timeout(...);
    // 파싱 후 반환
  } catch (e) {
    throw NetworkException('API 요청 실패', e);
  }
}
```

### 호출측 (캐시 fallback이 있는 경우)

```dart
try {
  final data = await _fetchData(url);
  // 정상 처리
} on NetworkException {
  // 캐시가 있으면 캐시 반환, 없으면 기본값
  return cached ?? Meal(meal: ApiStrings.mealNoData, ...);
}
```

---

## 적용 범위

| 파일 | 사용하는 예외 | 설명 |
|------|-------------|------|
| `meal_data_api.dart` | `NetworkException` | `_fetchData` throw, 상위 메서드에서 캐시 fallback |
| `timetable_data_api.dart` | `NetworkException` | 동일 패턴, 에러 맵 또는 빈 리스트 반환 |
| `notice_data_api.dart` | `NetworkException` | 동일 패턴, 기본 문자열 또는 null 반환 |
