# SearchTokens

> `lib/data/search_tokens.dart` — 한국어 2-gram 토큰화

Firestore는 LIKE/full-text 검색이 없으므로, 글 작성 시 제목+본문을 2-gram으로 분해해 `searchTokens` 배열에 저장하고, 검색 시 `array-contains-any` 쿼리로 매칭한다

예) `"기말고사 일정"` → `['기말', '말고', '고사', '일정']`

---

## `forDocument`

```dart
static List<String> forDocument(String title, String content, {int maxTokens = 200})
```

**설명**: 글 저장 시 사용. 제목+본문을 합쳐 2-gram 토큰을 생성한다

```dart
final combined = '$title $content';
final tokens = _ngrams(combined);
if (tokens.length <= maxTokens) return tokens.toList();
return tokens.take(maxTokens).toList();
```

- Set으로 자동 중복 제거
- **maxTokens = 200**: Firestore 배열 크기 + 저장 비용 제한

---

## `forQuery`

```dart
static List<String> forQuery(String query, {int maxTokens = 10})
```

**설명**: 검색 시 사용. 사용자 쿼리에서 2-gram을 추출한다

```dart
final cleaned = _normalize(query);
if (cleaned.length == 1) return [cleaned];  // 1글자는 그대로 반환
final tokens = _ngrams(query);
return tokens.take(maxTokens).toList();
```

- **maxTokens = 10**: Firestore `array-contains-any` 한계는 30이지만 10개면 충분
- 1글자 쿼리는 2-gram 생성 불가 → 1-gram 한 개 반환 (결과 없음 가능)

---

## `_ngrams`

```dart
static Set<String> _ngrams(String text)
```

**설명**: 정규화된 텍스트에서 연속 2글자 조합(sliding window)을 Set으로 생성한다

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

**설명**: 텍스트를 검색용으로 정규화한다

1. 소문자 변환: `text.toLowerCase()`
2. 허용 문자만 남기고 나머지 제거:
   - `0x30~0x39`: 숫자 (0-9)
   - `0x61~0x7A`: 영소문자 (a-z)
   - `0xAC00~0xD7A3`: 한글 음절 (가~힣)
3. 공백, 기호, 한자, 이모지 등 모두 제거

```dart
for (final r in lower.runes) {
  if (r >= 0x30 && r <= 0x39) { buf.writeCharCode(r); continue; }
  if (r >= 0x61 && r <= 0x7A) { buf.writeCharCode(r); continue; }
  if (r >= 0xAC00 && r <= 0xD7A3) { buf.writeCharCode(r); continue; }
}
```
