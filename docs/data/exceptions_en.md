# Exceptions

> 한국어: [exceptions.md](./exceptions.md)

> `lib/data/exceptions.dart` — Custom exception class hierarchy

---

## Class hierarchy

```
Exception
└── AppException (base)
    ├── NetworkException — HTTP timeout, connection failure
    ├── ApiException — API response parsing failure, abnormal response
    └── AuthException — Auth/permission related errors
```

All exception classes carry a `message` (description) and a `cause` (original error, optional).

---

## Usage patterns

### API layer (`_fetchData`)

```dart
// Lowest-level HTTP call — throws NetworkException on failure
static Future<Map<String, dynamic>> _fetchData(String url) async {
  try {
    final response = await _client.get(Uri.parse(url)).timeout(...);
    // parse and return
  } catch (e) {
    throw NetworkException('API 요청 실패', e);
  }
}
```

### Caller (when a cache fallback exists)

```dart
try {
  final data = await _fetchData(url);
  // normal handling
} on NetworkException {
  // return cache if available, otherwise default value
  return cached ?? Meal(meal: ApiStrings.mealNoData, ...);
}
```

---

## Scope

| File | Exception used | Description |
|------|-------------|------|
| `meal_data_api.dart` | `NetworkException` | `_fetchData` throws; upper method falls back to cache |
| `timetable_data_api.dart` | `NetworkException` | Same pattern; returns error map or empty list |
| `notice_data_api.dart` | `NetworkException` | Same pattern; returns default string or null |
