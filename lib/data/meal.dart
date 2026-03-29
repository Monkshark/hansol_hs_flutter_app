/// 급식 데이터 모델
///
/// - 메뉴, 날짜, 식사유형(조식/중식/석식), 칼로리 정보 포함
/// - JSON 직렬화/역직렬화 지원 (toJson/fromJson)
/// - 캐시 저장 및 API 응답 파싱에 사용
class Meal {
  final String? meal;
  final DateTime date;
  final int mealType;
  final String kcal;

  Meal({
    required this.meal,
    required this.date,
    required this.mealType,
    required this.kcal,
  });

  @override
  String toString() {
    return meal ?? '';
  }

  Map<String, dynamic> toJson() => {
        'meal': meal,
        'date': date.toIso8601String(),
        'mealType': mealType,
        'kcal': kcal,
      };

  factory Meal.fromJson(Map<String, dynamic> json) => Meal(
        meal: json['meal'],
        date: DateTime.parse(json['date']),
        mealType: json['mealType'],
        kcal: json['kcal'],
      );

  String getMealType() {
    switch (mealType) {
      case 1:
        return "조식";
      case 2:
        return "중식";
      case 3:
        return "석식";
      default:
        return "중식";
    }
  }
}
