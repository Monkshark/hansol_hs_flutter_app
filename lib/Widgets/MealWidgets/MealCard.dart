import 'package:flutter/material.dart';

class MealCard extends StatelessWidget {
  final String mealType;
  final Future<String> mealKcal;
  final Future<String> mealInfo;

  const MealCard({
    Key? key,
    required this.mealType,
    required this.mealKcal,
    required this.mealInfo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 65,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    mealType,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 5),
              FutureBuilder<String>(
                future: mealKcal,
                builder:
                    (BuildContext context, AsyncSnapshot<String> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Text(
                      snapshot.data!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFFC0C0C0),
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
          child: FutureBuilder<String>(
            future: mealInfo,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return Text(
                  snapshot.data!,
                  style: const TextStyle(
                    fontSize: 19,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
