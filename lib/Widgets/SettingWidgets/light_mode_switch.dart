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
        color: Colors.white,
      ),
      width: Device.getWidth(30),
      height: Device.getWidth(30),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Device.getWidth(10),
              height: Device.getWidth(10),
              padding: EdgeInsets.all(Device.getWidth(2)),
              decoration: BoxDecoration(
                color: Color(0xFFFF9500),
                borderRadius: BorderRadius.circular(
                  Device.getWidth(5),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.fill,
                child: Icon(
                  Icons.light_mode,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: Device.getWidth(1),
            ),
            Text(
              "라이트 모드",
              style: TextStyle(
                fontSize: Device.getWidth(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
