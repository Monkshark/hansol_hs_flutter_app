# BoardCategories

> `lib/data/board_categories.dart` — 게시판 카테고리 상수 + 헬퍼

Firestore에 저장되는 카테고리 값은 한국어(`'자유'`, `'질문'` 등)이므로, 영문 상수명으로 참조하여 오타·불일치를 방지. l10n 이름, 색상, FCM 토픽 키를 한 곳에서 관리

---

## 상수

| 상수 | Firestore 값 | 설명 |
|------|-------------|------|
| `all` | `'전체'` | 전체 탭 (필터 없음) |
| `popular` | `'인기글'` | 인기글 탭 (likeCount 정렬) |
| `free` | `'자유'` | 자유 게시판 |
| `question` | `'질문'` | 질문 게시판 |
| `info` | `'정보공유'` | 정보공유 게시판 |
| `lostFound` | `'분실물'` | 분실물 게시판 |
| `council` | `'학생회'` | 학생회 게시판 |
| `club` | `'동아리'` | 동아리 게시판 |

---

## 리스트

| 리스트 | 내용 | 용도 |
|--------|------|------|
| `boardKeys` | 전체 8개 (all ~ club) | 게시판 탭 바 |
| `writeKeys` | 6개 (all·popular 제외) | 글 작성 시 카테고리 선택 |

---

## `topicKey`

```dart
static const topicKey = <String, String>{
  free: 'free',
  question: 'question',
  info: 'info',
  lostFound: 'lost',      // 'lostfound'가 아님 — 기존 FCM 구독자 호환
  council: 'council',
  club: 'club',
};
```

FCM 토픽 이름 생성에 사용: `board_${topicKey[category]}`

> `lostFound`의 토픽 키가 `'lost'`인 이유: 기존에 `board_lost`로 구독된 사용자가 있어 변경 불가

---

## `localizedName`

```dart
static String localizedName(AppLocalizations l, String key)
```

카테고리 키 → l10n 이름 변환. `AppLocalizations`의 `board_categoryXxx` 키에 매핑

```dart
BoardCategories.localizedName(l, BoardCategories.free)  // → "자유" (ko) / "Free" (en)
```

---

## `color`

```dart
static Color color(String category)
```

카테고리 → 색상 매핑. 게시판 카드, 카테고리 뱃지, 홈 화면 최신글에서 사용

| 카테고리 | 색상 |
|----------|------|
| free | `AppColors.theme.primaryColor` |
| question | `AppColors.theme.secondaryColor` |
| info | `AppColors.theme.tertiaryColor` |
| lostFound | `#FF5722` (Deep Orange) |
| council | `#4CAF50` (Green) |
| club | `#9C27B0` (Purple) |
| 기타 | `AppColors.theme.darkGreyColor` |

---

## 사용 위치

- **board_screen.dart**: 탭 바, 카테고리 필터, PostCard 뱃지
- **write_post_screen.dart**: 카테고리 선택 드롭다운
- **post_detail_screen.dart**: 카테고리 색상 표시
- **home_screen.dart**: 최신글 카테고리 색상
- **[fcm_service](../notification/fcm_service.md)**: 토픽 구독/해제
