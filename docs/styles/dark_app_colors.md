# DarkAppColors

> `lib/styles/dark_app_colors.dart` — 다크 테마 색상 구현체

`AppColors` 추상 클래스를 구현. 싱글턴 패턴. 토스(Toss) 스타일 네이비 계열 배경색 사용.

---

## 싱글턴

```dart
class DarkAppColors extends AppColors {
  static final DarkAppColors _instance = DarkAppColors._internal();
  factory DarkAppColors() => _instance;
  DarkAppColors._internal();
}
```

`AppColors._dark`에서 `DarkAppColors()`로 접근.

---

## 색상 정의

| 프로퍼티 | 색상값 | 용도 |
|----------|--------|------|
| `black` | `0xFFEEEEEE` | 다크 모드의 "검정" = 밝은 회색 (텍스트용) |
| `white` | `0xFF191B20` | 다크 모드의 "흰색" = 진한 네이비 (배경용) |
| `primaryColor` | `0xFF3D5A80` | 주 색상 — 네이비 블루 |
| `secondaryColor` | `0xFF4CAF50` | 보조 색상 — 초록 |
| `tertiaryColor` | `0xFF7EB8DA` | 3차 색상 — 밝은 하늘색 |
| `lighterColor` | `rgba(61,90,128, 0.5)` | 반투명 주 색상 |
| `lightGreyColor` | `0xFF252830` | 밝은 회색 → 진한 회색 (카드 배경 등) |
| `darkGreyColor` | `0xFF8B8F99` | 어두운 회색 (보조 텍스트) |
| `textFiledFillColor` | `0xFF2A2D35` | 텍스트필드 배경 |
| `settingScreenBackgroundColor` | `0xFF17191E` | 설정 화면 배경 (가장 어두운 색) |
| `mealCardBackgroundColor` | `0xFF1E2028` | 급식 카드 배경 |
| `mealTypeTextColor` | `0xFF8B8F99` | 급식 유형 라벨 색상 |
| `mealHeaderIconColor` | `0xFF2A2D35` | 급식 헤더 아이콘 배경 |

---

## 디자인 특징

- **반전 패턴**: `black`이 밝은색, `white`가 어두운색. `AnimatedAppColors._lerp`에서 라이트↔다크 보간 시 자연스럽게 전환됨
- **네이비 계열**: 순수 검정(`#000000`) 대신 `0xFF191B20`, `0xFF1E2028` 등 약간의 파란 기가 있는 어두운 색 사용 — 눈의 피로 감소
- `darkGreyColor`(`0xFF8B8F99`)는 라이트/다크 모두 비슷한 톤으로 보조 텍스트에 일관성 유지
