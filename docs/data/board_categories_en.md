# BoardCategories

> 한국어: [board_categories.md](./board_categories.md)

> `lib/data/board_categories.dart` — Board category constants + helpers

Category values stored in Firestore are Korean (`'자유'`, `'질문'`, etc.). Referencing them by English constant names prevents typos and mismatches. Centralizes l10n names, colors, and FCM topic keys in one place.

---

## Constants

| Constant | Firestore value | Description |
|------|-------------|------|
| `all` | `'전체'` | All tab (no filter) |
| `popular` | `'인기글'` | Popular tab (sorted by likeCount) |
| `free` | `'자유'` | Free board |
| `question` | `'질문'` | Question board |
| `info` | `'정보공유'` | Info sharing board |
| `lostFound` | `'분실물'` | Lost & found board |
| `council` | `'학생회'` | Student council board |
| `club` | `'동아리'` | Club board |

---

## Lists

| List | Contents | Usage |
|--------|------|------|
| `boardKeys` | All 8 (all ~ club) | Board tab bar |
| `writeKeys` | 6 (excluding all·popular) | Category selection when writing a post |

---

## `topicKey`

```dart
static const topicKey = <String, String>{
  free: 'free',
  question: 'question',
  info: 'info',
  lostFound: 'lost',      // not 'lostfound' — for compatibility with existing FCM subscribers
  council: 'council',
  club: 'club',
};
```

Used for FCM topic name generation: `board_${topicKey[category]}`

> Reason `lostFound`'s topic key is `'lost'`: existing users subscribed to `board_lost`, so it cannot be changed.

---

## `localizedName`

```dart
static String localizedName(AppLocalizations l, String key)
```

Converts a category key to the l10n name. Maps to the `board_categoryXxx` keys in `AppLocalizations`.

```dart
BoardCategories.localizedName(l, BoardCategories.free)  // → "자유" (ko) / "Free" (en)
```

---

## `color`

```dart
static Color color(String category)
```

Maps category to color. Used in board cards, category badges, and recent posts on the home screen.

| Category | Color |
|----------|------|
| free | `AppColors.theme.primaryColor` |
| question | `AppColors.theme.secondaryColor` |
| info | `AppColors.theme.tertiaryColor` |
| lostFound | `#FF5722` (Deep Orange) |
| council | `#4CAF50` (Green) |
| club | `#9C27B0` (Purple) |
| other | `AppColors.theme.darkGreyColor` |

---

## Usage locations

- **board_screen.dart**: tab bar, category filter, PostCard badge
- **write_post_screen.dart**: category selection dropdown
- **post_detail_screen.dart**: category color display
- **home_screen.dart**: recent post category color
- **[fcm_service](../notification/fcm_service.md)**: topic subscribe/unsubscribe
