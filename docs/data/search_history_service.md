# SearchHistoryService

> `lib/data/search_history_service.dart` — 검색 기록 (최대 10개)

모든 메서드가 `static`. SharedPreferences에 JSON 배열로 저장. 로컬 전용 (Firestore 동기화 없음)

---

## `load`

```dart
static Future<List<String>> load()
```

**설명**: 저장된 검색 기록을 로드함

```dart
final raw = prefs.getString(_key);  // 'board_search_history'
final decoded = jsonDecode(raw);
return decoded.whereType<String>().toList();
```

파싱 실패 시 빈 리스트 반환 (silent fail)

---

## `add`

```dart
static Future<void> add(String query)
```

**설명**: 검색어를 기록에 추가함. 중복 제거 + FIFO

```dart
final trimmed = query.trim();
if (trimmed.isEmpty) return;
current.removeWhere((e) => e == trimmed);  // 기존 중복 제거
current.insert(0, trimmed);                // 맨 앞에 추가
final capped = current.take(_maxEntries).toList();  // 최대 10개
```

같은 검색어를 다시 입력하면 맨 앞으로 이동

---

## `remove`

```dart
static Future<void> remove(String query)
```

특정 검색어 한 개를 기록에서 삭제

---

## `clear`

```dart
static Future<void> clear()
```

검색 기록 전체 삭제. `prefs.remove(_key)`
