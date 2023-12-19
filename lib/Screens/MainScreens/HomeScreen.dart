import 'package:flutter/material.dart';
import 'package:hansol_high_school/API/MealDataApi.dart';
import 'package:hansol_high_school/Widgets/MealWidgets/MealCard.dart';

class HansolHighSchool extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 20.0,
        ),
        MealCard(
          mealType: "조식",
          mealKcal: MealDataApi.getMeal(
            date: DateTime.now(),
            mealType: MealDataApi.BREAKFAST,
            type: MealDataApi.CALORIE,
          ),
          mealInfo: MealDataApi.getMeal(
            date: DateTime.now(),
            mealType: MealDataApi.BREAKFAST,
            type: MealDataApi.MENU,
          ),
        ),
      ],
    );
  }
}
