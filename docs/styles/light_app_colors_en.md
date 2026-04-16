# LightAppColors

> 한국어: [light_app_colors.md](./light_app_colors.md)

> `lib/styles/light_app_colors.dart` — Light theme color implementation

Implements the [`AppColors`](app_colors.md) abstract class. Singleton pattern. Uses a blue-family primaryColor with bright background colors.

---

## Singleton

```dart
class LightAppColors extends AppColors {
  static final LightAppColors _instance = LightAppColors._internal();
  factory LightAppColors() => _instance;
  LightAppColors._internal();
}
```

Accessed via `LightAppColors()` inside `AppColors._light`.

---

## Color definitions

| Property | Color value | Usage |
|----------|-------------|-------|
| `black` | `Colors.black` | Default text color |
| `white` | `Colors.white` | Default background color |
| `primaryColor` | `0xFF3F72AF` | Primary color — calm blue |
| `secondaryColor` | `0xFF198A43` | Secondary color — deep green |
| `tertiaryColor` | `0xFF4D99F4` | Tertiary color — bright blue |
| `lighterColor` | `rgba(63,114,175, 0.6)` | Translucent primary color |
| `lightGreyColor` | `Colors.grey[200]` | Light grey (card background, dividers) |
| `darkGreyColor` | `Colors.grey[600]` | Dark grey (secondary text) |
| `textFiledFillColor` | `Colors.grey[300]` | Text-field background |
| `settingScreenBackgroundColor` | `0xFFF8F6F6` | Settings screen background (slightly warm grey) |
| `mealCardBackgroundColor` | `0xFFDBE2EF` | Meal card background (pale blue-grey) |
| `mealTypeTextColor` | `0xFF848484` | Meal type label color |
| `mealHeaderIconColor` | `0xFFDBE2EF` | Meal header icon background |

---

## Design traits

- **Blue tone**: `primaryColor` (`0xFF3F72AF`) is the app's overall keynote — AppBar, buttons, links, selection indicators.
- **Meal card**: `mealCardBackgroundColor` (`0xFFDBE2EF`) is a pale variant of primaryColor for visual cohesion.
- `lightGreyColor` / `darkGreyColor` use Flutter's stock `Colors.grey` palette — platform-friendly.
- `settingScreenBackgroundColor` (`0xFFF8F6F6`) is a slightly warmer tone than pure white to visually distinguish the settings screen.
