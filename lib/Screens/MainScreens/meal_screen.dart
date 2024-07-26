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
  late Future<Meal?> breakfast;
  late Future<Meal?> lunch;
  late Future<Meal?> dinner;

  bool isNullMealCardVisible = true;

  DateTime selectedDate = DateTime.now();

  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    setState(() {
      while (selectedDate.weekday == DateTime.saturday ||
          selectedDate.weekday == DateTime.sunday) {
        selectedDate = selectedDate.add(const Duration(days: 1));
      }
      dateController.text = selectedDate.toLocal().toString().split(' ')[0];
      fetchMeals();
    });
  }

  void fetchMeals() {
    setState(() {
      breakfast = MealDataApi.getMeal(
        date: selectedDate,
        mealType: MealDataApi.BREAKFAST,
        type: MealDataApi.MENU,
      );

      lunch = MealDataApi.getMeal(
        date: selectedDate,
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      );

      dinner = MealDataApi.getMeal(
        date: selectedDate,
        mealType: MealDataApi.DINNER,
        type: MealDataApi.MENU,
      );
    });
  }

  void _incrementDate() {
    setState(() {
      do {
        selectedDate = selectedDate.add(const Duration(days: 1));
      } while (selectedDate.weekday == DateTime.saturday ||
          selectedDate.weekday == DateTime.sunday);
      dateController.text = selectedDate.toLocal().toString().split(' ')[0];
      fetchMeals();
    });
  }

  void _decrementDate() {
    setState(() {
      do {
        selectedDate = selectedDate.subtract(const Duration(days: 1));
      } while (selectedDate.weekday == DateTime.saturday ||
          selectedDate.weekday == DateTime.sunday);
      dateController.text = selectedDate.toLocal().toString().split(' ')[0];
      fetchMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: _decrementDate,
                  ),
                  Text(
                    dateController.text,
                    style: const TextStyle(fontSize: 20),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: _incrementDate,
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Meal?>>(
                future: Future.wait([breakfast, lunch, dinner]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData) {
                    List<Meal?> meals = snapshot.data!;
                    List<Widget> mealCards = [];

                    for (Meal? meal in meals) {
                      // if (meal.meal != '급식 정보가 없습니다.' &&
                      //     isNullMealCardVisible) {
                      if (meal != null) {
                        mealCards.add(
                          MealCard(
                            meal: meal.meal,
                            date: meal.date,
                            mealType: meal.mealType,
                            kcal: meal.kcal,
                          ),
                        );
                      }
                      // }
                    }

                    if (mealCards.isEmpty) {
                      return const Center(
                          child: Text('No meal data available'));
                    }

                    return Column(
                      children: mealCards,
                    );
                  } else {
                    return const Center(child: Text('No meal data available'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
