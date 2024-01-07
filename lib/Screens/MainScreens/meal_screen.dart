import 'package:flutter/material.dart';
import 'package:hansol_high_school/API/meal_data_api.dart';
import 'package:hansol_high_school/Data/meal.dart';
import 'package:hansol_high_school/Widgets/MealWidgets/meal_card.dart';

class HansolHighSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MealScreen(),
    );
  }
}

class MealScreen extends StatefulWidget {
  @override
  _MealScreenState createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late Future<Meal> meal;
  late Future<String> kcal;

  @override
  void initState() {
    super.initState();
    meal = MealDataApi.getMeal(
        date: DateTime.now(),
        mealType: MealDataApi.BREAKFAST,
        type: MealDataApi.MENU) as Future<Meal>;
    kcal = MealDataApi.getMeal(
        date: DateTime.now(),
        mealType: MealDataApi.BREAKFAST,
        type: MealDataApi.CALORIE);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([meal, kcal]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            var data = snapshot.data as List;
            return Column(
              children: [
                MealCard(
                  meal: data[0],
                  date: DateTime.now(),
                  mealType: MealDataApi.BREAKFAST,
                  kcal: data[1],
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
