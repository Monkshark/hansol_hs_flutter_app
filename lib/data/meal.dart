import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

/// 급식 데이터 모델 (freezed)
///
/// - 메뉴, 날짜, 식사유형(조식/중식/석식), 칼로리, 영양정보 포함
/// - JSON 직렬화/역직렬화는 json_serializable이 자동 생성
@freezed
class Meal with _$Meal {
  const Meal._();

  const factory Meal({
    required String? meal,
    required DateTime date,
    required int mealType,
    required String kcal,
    @Default('') String ntrInfo,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);

  @override
  String toString() => meal ?? '';

  String getMealType() {
    switch (mealType) {
      case 1:
        return '조식';
      case 2:
        return '중식';
      case 3:
        return '석식';
      default:
        return '중식';
    }
  }
}
