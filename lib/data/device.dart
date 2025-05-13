import 'package:flutter/material.dart';

class Device {
  static late double width;
  static late double height;

  static late bool isTablet;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    width = size.width;
    height = size.height;
    isTablet = width > 500;
  }

  static double getWidth(double percent) {
    return width / 100 * percent;
  }

  static double getHeight(double percent) {
    return height / 100 * percent;
  }
}

