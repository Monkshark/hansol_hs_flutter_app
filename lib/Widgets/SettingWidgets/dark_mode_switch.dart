import 'package:flutter/material.dart';

class DarkModeSwitch extends StatefulWidget {
  final ThemeMode currentMode;
  final bool isSelected;

  const DarkModeSwitch({
    Key? key,
    required this.currentMode,
    required this.isSelected,
  }) : super(key: key);

  @override
  State<DarkModeSwitch> createState() => _DarkModeSwitchState();
}

class _DarkModeSwitchState extends State<DarkModeSwitch> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
