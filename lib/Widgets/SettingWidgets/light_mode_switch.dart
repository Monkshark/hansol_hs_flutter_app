import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/device.dart';

class LightModeSwitch extends StatefulWidget {
  final ThemeMode currentMode;
  final bool isSelected;

  const LightModeSwitch({
    Key? key,
    required this.currentMode,
    required this.isSelected,
  }) : super(key: key);

  @override
  State<LightModeSwitch> createState() => _LightModeSwitchState();
}

class _LightModeSwitchState extends State<LightModeSwitch> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SizedBox(
        width: Device.getWidth(30),
        height: Device.getHeight(30),
        child: Center(
          child: SizedBox(
            width: Device.getWidth(10),
            height: Device.getHeight(10),
            child: Icon(
              Icons.light_mode,
            ),
          ),
        ),
      ),
    );
  }
}
