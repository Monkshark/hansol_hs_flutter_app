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
  late Future<Meal?> meal;

  @override
  void initState() {
    super.initState();
    meal = MealDataApi.getMeal(
        date: DateTime.now().add(const Duration(days: 1)),
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Meal?>(
        future: meal,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else if (snapshot.hasData && snapshot.data != null) {
            Meal? mealData = snapshot.data;
            return Column(
              children: [
                MealCard(
                  meal: mealData!.meal,
                  date: mealData.date,
                  mealType: mealData.mealType,
                  kcal: mealData.kcal,
                ),
              ],
            );
          } else {
            return const Text('No meal data available');
          }
        },
      ),
    );
  }
}