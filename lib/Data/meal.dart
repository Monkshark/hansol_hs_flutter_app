class Meal {
  final String meal;
  final DateTime date;
  final int mealType;
  final String kcal;

  Meal({
    required this.meal,
    required this.date,
    required this.mealType,
    required this.kcal,
  });

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
}
