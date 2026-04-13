# AppColors

> `lib/styles/app_colors.dart` — 테마 컬러 + AnimatedAppColors

---

## `AppColors` (추상 클래스)

라이트/다크 테마의 색상 속성을 추상으로 정의. 총 13개 색상 프로퍼티

### 정적 접근자

| 접근자 | 설명 |
|--------|------|
| `AppColors.theme` | `AnimatedAppColors.instance` — 현재 보간된 색상 |
| `AppColors.lightTheme` | [`LightAppColors`](light_app_colors.md)`()` — 라이트 테마 고정 색상 |
| `AppColors.darkTheme` | [`DarkAppColors`](dark_app_colors.md)`()` — 다크 테마 고정 색상 |

---

## 색상 팔레트

| 프로퍼티 | 라이트 (hex) | 다크 (hex) | 용도 |
|----------|-------------|-----------|------|
| `primaryColor` | `#3F72AF` | `#3D5A80` | 앱바, 게시판 자유 뱃지, 주요 강조색 |
| `secondaryColor` | `#198A43` | `#4CAF50` | 게시판 질문 뱃지 |
| `tertiaryColor` | `#4D99F4` | `#7EB8DA` | 게시판 정보공유 뱃지, 보조 강조색 |
| `lighterColor` | `rgba(63,114,175,0.6)` | `rgba(61,90,128,0.5)` | primaryColor의 투명도 변형 |
| `lightGreyColor` | `grey[200]` | `#252830` | 구분선, 배경 박스 |
| `darkGreyColor` | `grey[600]` | `#8B8F99` | 보조 텍스트, 기본 뱃지 |
| `textFiledFillColor` | `grey[300]` | `#2A2D35` | 텍스트 입력 필드 배경 |
| `settingScreenBackgroundColor` | `#F8F6F6` | `#17191E` | 설정 화면 배경 |
| `mealCardBackgroundColor` | `#DBE2EF` | `#1E2028` | 급식 카드 배경 |
| `mealTypeTextColor` | `#666666` | `#9EA2AC` | 급식 타입 라벨 (조식/중식/석식) |
| `mealHeaderIconColor` | `#DBE2EF` | `#2A2D35` | 급식 헤더 아이콘 |
| `black` | `#000000` | `#EEEEEE` | 주요 텍스트 (다크에서는 반전) |
| `white` | `#FFFFFF` | `#191B20` | 카드 배경 (다크에서는 반전) |

### 디자인 의도

- **black/white 반전**: 다크 모드에서 `black`은 밝은 텍스트색(`#EEEEEE`), `white`는 어두운 배경(`#191B20`)으로 매핑. 시맨틱 네이밍이 아닌 역할 네이밍 — "주요 텍스트색"과 "주요 배경색"으로 이해해야 함
- **게시판 카테고리 색상**: `primaryColor`(자유) · `secondaryColor`(질문) · `tertiaryColor`(정보공유)은 [`BoardCategories.color()`](../data/board_categories.md)에서 사용. 분실물/학생회/동아리는 하드코딩 hex 사용
- **접근성**: 라이트 모드 텍스트(`#000000`) on 배경(`#F2F3F5`)은 대비율 16.1:1 (WCAG AAA). 다크 모드 텍스트(`#EEEEEE`) on 배경(`#17191E`)은 대비율 14.4:1 (WCAG AAA). 보조 텍스트(`darkGreyColor`)는 각각 5.7:1 / 4.6:1 (WCAG AA)

---

## `AnimatedAppColors` (싱글톤)

```dart
class AnimatedAppColors extends AppColors {
  static final AnimatedAppColors instance = AnimatedAppColors._();
}
```

라이트↔다크 전환 시 색상 보간(lerp)을 지원하는 싱글톤

### `setDark(dark, {animate})`

```dart
void setDark(bool dark, {bool animate = true}) {
  _isDark = dark;
  if (!animate) _t = dark ? 1.0 : 0.0;
}
```

테마 방향 설정. `animate: false`면 즉시 전환 (앱 초기화 시)

### `tick(t)`

```dart
void tick(double t) => _t = t;
```

`AnimationController`에서 호출. `_t`는 0.0(라이트)~1.0(다크) 보간 진행도

### 색상 보간

```dart
Color _lerp(Color light, Color dark) => Color.lerp(light, dark, _t)!;

@override Color get primaryColor =>
    _lerp(AppColors.lightTheme.primaryColor, AppColors.darkTheme.primaryColor);
```

모든 색상 프로퍼티가 `_lerp`를 통해 현재 `_t` 값에 따라 라이트/다크 사이를 보간. 테마 전환 애니메이션 시 부드러운 색상 전환 구현

### 호출 흐름

```
themeProvider 변경
  → HansolHighSchool.build()
    → AnimatedAppColors.setDark(isDark, animate: false)
    → AnimatedAppColors.tick(isDark ? 1.0 : 0.0)
      → 모든 AppColors.theme.xxx 갱신
```

현재는 `animate: false`로 즉시 전환만 사용. 향후 `AnimationController`와 연결 시 0.0→1.0 애니메이션으로 부드러운 전환 가능
