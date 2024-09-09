import 'package:flutter/material.dart';
import 'package:hansol_high_school/API/meal_data_api.dart';
import 'package:hansol_high_school/Data/device.dart';
import 'package:hansol_high_school/Data/meal.dart';
import 'package:hansol_high_school/Widgets/MealWidgets/meal_card.dart';
import 'package:hansol_high_school/Widgets/MealWidgets/meal_header.dart';
import 'package:hansol_high_school/Widgets/MealWidgets/weekly_calendar.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';
import 'package:intl/intl.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({Key? key}) : super(key: key);

  @override
  State<MealScreen> createState() => _MealScreenState();
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
      dateController.text = selectedDate.toLocal().toString().split(' ').first;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.color.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            WeeklyCalendar(
              backgroundColor: AppColors.color.primaryColor,
              onDaySelected: (dateTime) {
                setState(() {
                  selectedDate = dateTime;
                  fetchMeals();
                });
                print(DateFormat("M월 d일 E요일", 'ko_KR').format(selectedDate));
              },
            ),
            SizedBox(
              height: Device.getHeight(5),
              width: double.infinity,
              child: ColoredBox(
                color: AppColors.color.primaryColor,
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    MealHeader(
                      selectedDate: selectedDate,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Center(
                          child: FutureBuilder<List<Meal?>>(
                            future: Future.wait([breakfast, lunch, dinner]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Text('Error: ${snapshot.error}'),
                                );
                              } else if (snapshot.hasData) {
                                List<Meal?> meals = snapshot.data!;
                                List<Widget> mealCards = [];

                                for (Meal? meal in meals) {
                                  if (meal != null) {
                                    mealCards.add(
                                      SizedBox(
                                        height: Device.getHeight(3),
                                      ),
                                    );
                                    mealCards.add(
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            left: Device.getWidth(7.5),
                                          ),
                                          child: Text(
                                            meal.getMealType(),
                                            style: TextStyle(
                                              color: AppColors
                                                  .color.mealTypeTextColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                    mealCards.add(
                                      SizedBox(
                                        height: Device.getHeight(1),
                                      ),
                                    );
                                    mealCards.add(
                                      MealCard(
                                        meal: meal.meal,
                                        date: meal.date,
                                        mealType: meal.mealType,
                                        kcal: meal.kcal,
                                      ),
                                    );
                                    mealCards.add(
                                      SizedBox(
                                        height: Device.getHeight(1),
                                      ),
                                    );
                                  }
                                }

                                if (mealCards.isEmpty) {
                                  return const Center(
                                    child: Text('No meal data available'),
                                  );
                                }

                                return Column(
                                  children: mealCards,
                                );
                              } else {
                                return const Center(
                                  child: Text('No meal data available'),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
