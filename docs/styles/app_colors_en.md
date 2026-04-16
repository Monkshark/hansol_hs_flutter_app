# AppColors

> 한국어: [app_colors.md](./app_colors.md)

> `lib/styles/app_colors.dart` — Theme colors + AnimatedAppColors

---

## `AppColors` (abstract class)

Abstractly defines color properties for the light/dark themes. Total of 13 color properties.

### Static accessors

| Accessor | Description |
|----------|-------------|
| `AppColors.theme` | `AnimatedAppColors.instance` — current interpolated colors |
| `AppColors.lightTheme` | [`LightAppColors`](light_app_colors.md)`()` — fixed light-theme colors |
| `AppColors.darkTheme` | [`DarkAppColors`](dark_app_colors.md)`()` — fixed dark-theme colors |

---

## Color palette

| Property | Light (hex) | Dark (hex) | Usage |
|----------|-------------|------------|-------|
| `primaryColor` | `#3F72AF` | `#3D5A80` | App bar, free-board badge, primary accent |
| `secondaryColor` | `#198A43` | `#4CAF50` | Question-board badge |
| `tertiaryColor` | `#4D99F4` | `#7EB8DA` | Info-sharing board badge, secondary accent |
| `lighterColor` | `rgba(63,114,175,0.6)` | `rgba(61,90,128,0.5)` | Translucent variant of primaryColor |
| `lightGreyColor` | `grey[200]` | `#252830` | Dividers, background boxes |
| `darkGreyColor` | `grey[600]` | `#8B8F99` | Secondary text, default badges |
| `textFiledFillColor` | `grey[300]` | `#2A2D35` | Text-field background |
| `settingScreenBackgroundColor` | `#F8F6F6` | `#17191E` | Settings screen background |
| `mealCardBackgroundColor` | `#DBE2EF` | `#1E2028` | Meal card background |
| `mealTypeTextColor` | `#666666` | `#9EA2AC` | Meal type label (breakfast/lunch/dinner) |
| `mealHeaderIconColor` | `#DBE2EF` | `#2A2D35` | Meal header icon |
| `black` | `#000000` | `#EEEEEE` | Primary text (inverted in dark mode) |
| `white` | `#FFFFFF` | `#191B20` | Card background (inverted in dark mode) |

### Design intent

- **black/white inversion**: In dark mode, `black` maps to a light text color (`#EEEEEE`) and `white` maps to a dark background (`#191B20`). These are role-based names, not semantic — think of them as "primary text color" and "primary background color".
- **Board category colors**: `primaryColor` (Free) · `secondaryColor` (Question) · `tertiaryColor` (Info-sharing) are used by [`BoardCategories.color()`](../data/board_categories.md). Lost-and-found/student council/clubs use hard-coded hex.
- **Accessibility**: Light-mode text (`#000000`) on background (`#F2F3F5`) has a contrast ratio of 16.1:1 (WCAG AAA). Dark-mode text (`#EEEEEE`) on background (`#17191E`) has a contrast ratio of 14.4:1 (WCAG AAA). Secondary text (`darkGreyColor`) measures 5.7:1 / 4.6:1 respectively (WCAG AA).

---

## `AnimatedAppColors` (singleton)

```dart
class AnimatedAppColors extends AppColors {
  static final AnimatedAppColors instance = AnimatedAppColors._();
}
```

A singleton supporting color interpolation (lerp) during light↔dark transitions.

### `setDark(dark, {animate})`

```dart
void setDark(bool dark, {bool animate = true}) {
  _isDark = dark;
  if (!animate) _t = dark ? 1.0 : 0.0;
}
```

Sets the theme direction. `animate: false` switches instantly (used during app init).

### `tick(t)`

```dart
void tick(double t) => _t = t;
```

Called from `AnimationController`. `_t` is the interpolation progress 0.0 (light) ~ 1.0 (dark).

### Color interpolation

```dart
Color _lerp(Color light, Color dark) => Color.lerp(light, dark, _t)!;

@override Color get primaryColor =>
    _lerp(AppColors.lightTheme.primaryColor, AppColors.darkTheme.primaryColor);
```

Every color property is interpolated between light and dark via `_lerp` based on the current `_t`. This produces smooth color transitions during theme-switch animations.

### Call flow

```
themeProvider change
  → HansolHighSchool.build()
    → AnimatedAppColors.setDark(isDark, animate: false)
    → AnimatedAppColors.tick(isDark ? 1.0 : 0.0)
      → all AppColors.theme.xxx refreshed
```

Currently only uses `animate: false` (instant switch). If later connected to an `AnimationController`, a 0.0→1.0 animation would enable smooth transitions.
