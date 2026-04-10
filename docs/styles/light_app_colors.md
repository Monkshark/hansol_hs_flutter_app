# LightAppColors

> `lib/styles/light_app_colors.dart` — 라이트 테마 색상 구현체

[`AppColors`](app_colors.md) 추상 클래스를 구현. 싱글턴 패턴. 블루 계열 primaryColor와 밝은 배경색 사용.

---

## 싱글턴

```dart
class LightAppColors extends AppColors {
  static final LightAppColors _instance = LightAppColors._internal();
  factory LightAppColors() => _instance;
  LightAppColors._internal();
}
```

`AppColors._light`에서 `LightAppColors()`로 접근.

---

## 색상 정의

| 프로퍼티 | 색상값 | 용도 |
|----------|--------|------|
| `black` | `Colors.black` | 기본 텍스트 색상 |
| `white` | `Colors.white` | 기본 배경 색상 |
| `primaryColor` | `0xFF3F72AF` | 주 색상 — 차분한 블루 |
| `secondaryColor` | `0xFF198A43` | 보조 색상 — 진한 초록 |
| `tertiaryColor` | `0xFF4D99F4` | 3차 색상 — 밝은 파랑 |
| `lighterColor` | `rgba(63,114,175, 0.6)` | 반투명 주 색상 |
| `lightGreyColor` | `Colors.grey[200]` | 밝은 회색 (카드 배경, 구분선) |
| `darkGreyColor` | `Colors.grey[600]` | 어두운 회색 (보조 텍스트) |
| `textFiledFillColor` | `Colors.grey[300]` | 텍스트필드 배경 |
| `settingScreenBackgroundColor` | `0xFFF8F6F6` | 설정 화면 배경 (약간 따뜻한 회색) |
| `mealCardBackgroundColor` | `0xFFDBE2EF` | 급식 카드 배경 (연한 파란 회색) |
| `mealTypeTextColor` | `0xFF848484` | 급식 유형 라벨 색상 |
| `mealHeaderIconColor` | `0xFFDBE2EF` | 급식 헤더 아이콘 배경 |

---

## 디자인 특징

- **블루 톤**: `primaryColor`(`0xFF3F72AF`)가 앱 전체의 기조 — AppBar, 버튼, 링크, 선택 인디케이터
- **급식 카드**: `mealCardBackgroundColor`(`0xFFDBE2EF`)는 primaryColor의 연한 변형으로 시각적 통일감
- `lightGreyColor` / `darkGreyColor`는 Flutter 기본 `Colors.grey` 팔레트 사용 — 플랫폼 친화적
- `settingScreenBackgroundColor`(`0xFFF8F6F6`)는 순수 흰색보다 약간 따뜻한 톤으로 설정 화면 구분
