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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        color: Colors.blue,
      ),
      width: Device.getWidth(27),
      height: Device.getWidth(27),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: Device.getWidth(8),
              height: Device.getWidth(8),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Icon(
                  Icons.light_mode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
