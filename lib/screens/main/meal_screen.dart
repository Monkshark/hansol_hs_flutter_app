import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/api/meal_data_api.dart';
import 'package:hansol_high_school/data/meal.dart';
import 'package:hansol_high_school/widgets/meal/meal_card.dart';
import 'package:hansol_high_school/widgets/meal/meal_header.dart';
import 'package:hansol_high_school/widgets/meal/weekly_calendar.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class MealScreen extends StatefulWidget {
  const MealScreen({Key? key}) : super(key: key);

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  late Future<Meal?> breakfast;
  late Future<Meal?> lunch;
  late Future<Meal?> dinner;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    MealDataApi.prefetchWeek(selectedDate);
    fetchMeals();
  }

  void fetchMeals() {
    final prefetch = MealDataApi.prefetchWeek(selectedDate);
    setState(() {
      breakfast = prefetch.then((_) => MealDataApi.getMeal(
        date: selectedDate,
        mealType: MealDataApi.BREAKFAST,
        type: MealDataApi.MENU,
      ));
      lunch = prefetch.then((_) => MealDataApi.getMeal(
        date: selectedDate,
        mealType: MealDataApi.LUNCH,
        type: MealDataApi.MENU,
      ));
      dinner = prefetch.then((_) => MealDataApi.getMeal(
        date: selectedDate,
        mealType: MealDataApi.DINNER,
        type: MealDataApi.MENU,
      ));
    });
  }

  String _localizedMealType(BuildContext context, String key) {
    final l = AppLocalizations.of(context)!;
    switch (key) {
      case 'breakfast': return l.meal_breakfast;
      case 'lunch': return l.meal_lunch;
      case 'dinner': return l.meal_dinner;
      default: return l.meal_lunch;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.theme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            WeeklyCalendar(
              backgroundColor: AppColors.theme.primaryColor,
              onDaySelected: (dateTime) {
                setState(() {
                  selectedDate = dateTime;
                  fetchMeals();
                });
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    MealHeader(selectedDate: selectedDate),
                    Expanded(
                      child: FutureBuilder<List<Meal?>>(
                        future: Future.wait([breakfast, lunch, dinner]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text(AppLocalizations.of(context)!.meal_error(snapshot.error.toString())));
                          }
                          if (!snapshot.hasData) {
                            return Center(child: Text(AppLocalizations.of(context)!.meal_noInfo));
                          }

                          final meals = snapshot.data!;
                          final validMeals = meals.where((m) =>
                            m != null && m.meal != null && m.meal != '급식 정보가 없습니다.' && m.meal != '급식 정보가 없습니다').toList();

                          if (validMeals.isEmpty) {
                            final isWeekday = selectedDate.weekday <= 5;
                            return GestureDetector(
                              onTap: isWeekday ? () async {
                                await MealDataApi.clearCacheForDate(selectedDate);
                                fetchMeals();
                              } : null,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.no_meals, size: 40, color: AppColors.theme.darkGreyColor),
                                    const SizedBox(height: 8),
                                    Text(AppLocalizations.of(context)!.meal_noInfoEmpty,
                                      style: TextStyle(fontSize: 14, color: AppColors.theme.darkGreyColor)),
                                    if (isWeekday) ...[
                                      const SizedBox(height: 6),
                                      Text(AppLocalizations.of(context)!.meal_refreshHint,
                                        style: TextStyle(fontSize: 12, color: AppColors.theme.primaryColor)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
                            itemCount: validMeals.length,
                            itemBuilder: (context, index) {
                              final meal = validMeals[index]!;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4, bottom: 6),
                                      child: Text(
                                        _localizedMealType(context, meal.getMealTypeKey()),
                                        style: TextStyle(
                                          color: AppColors.theme.mealTypeTextColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    MealCard(
                                      meal: meal.meal,
                                      date: meal.date,
                                      mealType: meal.mealType,
                                      kcal: meal.kcal,
                                      ntrInfo: meal.ntrInfo,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
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
