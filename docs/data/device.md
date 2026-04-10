# Device

> `lib/data/device.dart` — 디바이스 크기 계산 유틸리티

모든 메서드가 `static`. 화면 크기를 퍼센트 기반으로 계산하는 반응형 레이아웃 헬퍼.

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

**설명**: 디바이스 크기를 초기화한다.

`MainScreen.build`에서 매 빌드마다 호출:
```dart
Device.init(context);
```

- `width`/`height`: `MediaQuery.of(context).size`에서 추출
- `isTablet`: 너비 500px 초과 시 태블릿으로 판정

---

## `getWidth`

```dart
static double getWidth(double percent) {
  return width / 100 * percent;
}
```

**설명**: 화면 너비의 퍼센트를 픽셀로 변환한다.

```dart
// 예: 화면 너비가 400px일 때
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

화면 높이의 퍼센트를 픽셀로 변환. `getWidth`와 동일한 계산 방식.

---

## 정적 필드

| 필드 | 타입 | 설명 |
|------|------|------|
| `width` | `double` | 화면 너비 (px) |
| `height` | `double` | 화면 높이 (px) |
| `isTablet` | `bool` | 태블릿 여부 (`width > 500`) |

---

## 사용처

위젯 크기/패딩을 화면 비율로 지정할 때 사용:
```dart
Container(
  width: Device.getWidth(90),   // 화면 너비의 90%
  height: Device.getHeight(5),  // 화면 높이의 5%
)
```
