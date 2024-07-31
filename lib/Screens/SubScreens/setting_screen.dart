import 'package:flutter/material.dart';

class SettingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text(''),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: List.generate(
                10,
                (index) => Container(
                  margin: const EdgeInsets.all(10),
                  color: Colors.blueAccent,
                  height: 150,
                  child: Center(
                    child: Text(
                      'Item ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
