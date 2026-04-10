# AppColors

> `lib/styles/app_colors.dart` — 테마 컬러 + AnimatedAppColors

---

## `AppColors` (추상 클래스)

```dart
abstract class AppColors {
  Color get primaryColor;
  Color get secondaryColor;
  Color get tertiaryColor;
  Color get lighterColor;
  Color get lightGreyColor;
  Color get darkGreyColor;
  Color get textFiledFillColor;
  Color get settingScreenBackgroundColor;
  Color get mealCardBackgroundColor;
  Color get mealTypeTextColor;
  Color get mealHeaderIconColor;
  // ...
}
```

라이트/다크 테마의 색상 속성을 추상으로 정의

### 정적 접근자

| 접근자 | 설명 |
|--------|------|
| `AppColors.theme` | `AnimatedAppColors.instance` — 현재 보간된 색상 |
| `AppColors.lightTheme` | [`LightAppColors`](light_app_colors.md)`()` — 라이트 테마 고정 색상 |
| `AppColors.darkTheme` | [`DarkAppColors`](dark_app_colors.md)`()` — 다크 테마 고정 색상 |

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

테마 방향 설정. `animate: false`면 즉시 전환 (초기화 시)

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
