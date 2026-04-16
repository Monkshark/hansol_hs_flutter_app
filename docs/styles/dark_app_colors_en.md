# DarkAppColors

> 한국어: [dark_app_colors.md](./dark_app_colors.md)

> `lib/styles/dark_app_colors.dart` — Dark theme color implementation

Implements the [`AppColors`](app_colors.md) abstract class. Singleton pattern. Uses Toss-style navy-tinted background colors.

---

## Singleton

```dart
class DarkAppColors extends AppColors {
  static final DarkAppColors _instance = DarkAppColors._internal();
  factory DarkAppColors() => _instance;
  DarkAppColors._internal();
}
```

Accessed via `DarkAppColors()` inside `AppColors._dark`.

---

## Color definitions

| Property | Color value | Usage |
|----------|-------------|-------|
| `black` | `0xFFEEEEEE` | Dark mode "black" = light grey (for text) |
| `white` | `0xFF191B20` | Dark mode "white" = deep navy (for backgrounds) |
| `primaryColor` | `0xFF3D5A80` | Primary color — navy blue |
| `secondaryColor` | `0xFF4CAF50` | Secondary color — green |
| `tertiaryColor` | `0xFF7EB8DA` | Tertiary color — light sky blue |
| `lighterColor` | `rgba(61,90,128, 0.5)` | Translucent primary color |
| `lightGreyColor` | `0xFF252830` | Light grey → dark grey (card background, etc.) |
| `darkGreyColor` | `0xFF8B8F99` | Dark grey (secondary text) |
| `textFiledFillColor` | `0xFF2A2D35` | Text-field background |
| `settingScreenBackgroundColor` | `0xFF17191E` | Settings screen background (darkest color) |
| `mealCardBackgroundColor` | `0xFF1E2028` | Meal card background |
| `mealTypeTextColor` | `0xFF8B8F99` | Meal type label color |
| `mealHeaderIconColor` | `0xFF2A2D35` | Meal header icon background |

---

## Design traits

- **Inversion pattern**: `black` is the light color and `white` is the dark color. This transitions naturally in `AnimatedAppColors._lerp` when interpolating between light↔dark.
- **Navy palette**: Instead of pure black (`#000000`), uses slightly blue-tinted dark tones such as `0xFF191B20` and `0xFF1E2028` — reduces eye strain.
- `darkGreyColor` (`0xFF8B8F99`) keeps a similar tone in both light and dark modes, maintaining consistency for secondary text.
