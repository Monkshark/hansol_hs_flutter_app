# SearchHistoryService

> 한국어: [search_history_service.md](./search_history_service.md)

> `lib/data/search_history_service.dart` — Search history (max 10 entries)

All methods are `static`. Stored as a JSON array in SharedPreferences. Local only (no Firestore sync).

---

## `load`

```dart
static Future<List<String>> load()
```

**Description**: Loads the saved search history.

```dart
final raw = prefs.getString(_key);  // 'board_search_history'
final decoded = jsonDecode(raw);
return decoded.whereType<String>().toList();
```

Returns an empty list on parse failure (silent fail).

---

## `add`

```dart
static Future<void> add(String query)
```

**Description**: Adds a query to history. Deduplicates + FIFO.

```dart
final trimmed = query.trim();
if (trimmed.isEmpty) return;
current.removeWhere((e) => e == trimmed);  // remove existing duplicate
current.insert(0, trimmed);                // insert at the front
final capped = current.take(_maxEntries).toList();  // up to 10
```

Re-entering the same query moves it to the front.

---

## `remove`

```dart
static Future<void> remove(String query)
```

Removes a single query from history.

---

## `clear`

```dart
static Future<void> clear()
```

Deletes the entire search history. `prefs.remove(_key)`.
