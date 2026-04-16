# SearchTokens

> 한국어: [search_tokens.md](./search_tokens.md)

> `lib/data/search_tokens.dart` — Korean 2-gram tokenization

Firestore has no LIKE/full-text search, so when a post is created, its title + body are broken into 2-grams and stored in the `searchTokens` array; on search, an `array-contains-any` query matches against them.

Example: `"기말고사 일정"` → `['기말', '말고', '고사', '일정']`

---

## `forDocument`

```dart
static List<String> forDocument(String title, String content, {int maxTokens = 200})
```

**Description**: Used when saving a post. Combines title + body and generates 2-gram tokens.

```dart
final combined = '$title $content';
final tokens = _ngrams(combined);
if (tokens.length <= maxTokens) return tokens.toList();
return tokens.take(maxTokens).toList();
```

- Set automatically removes duplicates
- **maxTokens = 200**: Limits Firestore array size and storage cost

---

## `forQuery`

```dart
static List<String> forQuery(String query, {int maxTokens = 10})
```

**Description**: Used at search time. Extracts 2-grams from the user's query.

```dart
final cleaned = _normalize(query);
if (cleaned.length == 1) return [cleaned];  // 1-char: return as-is
final tokens = _ngrams(query);
return tokens.take(maxTokens).toList();
```

- **maxTokens = 10**: Firestore's `array-contains-any` limit is 30, but 10 is enough
- 1-character queries cannot form a 2-gram → returns a single 1-gram (may yield no results)

---

## `_ngrams`

```dart
static Set<String> _ngrams(String text)
```

**Description**: Produces a Set of all consecutive 2-character combinations (sliding window) from the normalized text.

```dart
final cleaned = _normalize(text);
for (int i = 0; i + 2 <= cleaned.length; i++) {
  out.add(cleaned.substring(i, i + 2));
}
```

---

## `_normalize`

```dart
static String _normalize(String text)
```

**Description**: Normalizes text for search.

1. Lowercase: `text.toLowerCase()`
2. Keep only allowed characters; remove the rest:
   - `0x30~0x39`: digits (0–9)
   - `0x61~0x7A`: lowercase English letters (a–z)
   - `0xAC00~0xD7A3`: Korean syllables (가–힣)
3. Removes spaces, symbols, Chinese characters, emoji, etc.

```dart
for (final r in lower.runes) {
  if (r >= 0x30 && r <= 0x39) { buf.writeCharCode(r); continue; }
  if (r >= 0x61 && r <= 0x7A) { buf.writeCharCode(r); continue; }
  if (r >= 0xAC00 && r <= 0xD7A3) { buf.writeCharCode(r); continue; }
}
```
