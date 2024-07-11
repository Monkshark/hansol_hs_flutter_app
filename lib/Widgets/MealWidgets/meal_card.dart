import 'package:flutter/material.dart';
import 'package:hansol_high_school/Widgets/CalendarWidgets/main_calendar.dart';

class MealCard extends StatelessWidget {
  final String meal;
  final DateTime date;
  final int mealType;
  final String kcal;

  const MealCard({
    required this.meal,
    required this.date,
    required this.mealType,
    required this.kcal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.0,
      height: 160.0,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: PRIMARY_COLOR,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date.year.toString(),
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    getMealType(mealType),
                    style: const TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    kcal,
                    style: const TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 48.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(meal),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getYear(DateTime date) => date.year.toString();

  String getMonth(DateTime date) => date.month.toString().padLeft(2, '0');

  String getDay(DateTime date) => date.day.toString().padLeft(2, '0');

  String getMealType(int mealType) {
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
