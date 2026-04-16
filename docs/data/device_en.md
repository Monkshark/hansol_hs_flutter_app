# Device

> 한국어: [device.md](./device.md)

> `lib/data/device.dart` — Device size calculation utility

All methods are `static`. Responsive layout helper that calculates screen sizes based on percentages.

---

## `init`

```dart
static void init(BuildContext context) {
  final size = MediaQuery.of(context).size;
  width = size.width;
  height = size.height;
  isTablet = width > 500;
}
```

**Description**: Initializes the device size.

Called on every build in `MainScreen.build`:
```dart
Device.init(context);
```

- `width`/`height`: extracted from `MediaQuery.of(context).size`
- `isTablet`: treated as tablet when width exceeds 500px

---

## `getWidth`

```dart
static double getWidth(double percent) {
  return width / 100 * percent;
}
```

**Description**: Converts a percentage of the screen width to pixels.

```dart
// e.g. when screen width is 400px
Device.getWidth(50)  // → 200.0
Device.getWidth(90)  // → 360.0
```

---

## `getHeight`

```dart
static double getHeight(double percent) {
  return height / 100 * percent;
}
```

Converts a percentage of the screen height to pixels. Same calculation as `getWidth`.

---

## Static fields

| Field | Type | Description |
|------|------|------|
| `width` | `double` | Screen width (px) |
| `height` | `double` | Screen height (px) |
| `isTablet` | `bool` | Whether it is a tablet (`width > 500`) |

---

## Usage

Used to specify widget sizes/paddings as a proportion of the screen:
```dart
Container(
  width: Device.getWidth(90),   // 90% of screen width
  height: Device.getHeight(5),  // 5% of screen height
)
```
