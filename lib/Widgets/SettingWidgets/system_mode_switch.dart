import 'package:flutter/material.dart';

class SystemModeSwitch extends StatefulWidget {
  final ThemeMode currentMode;
  final bool isSelected;

  const SystemModeSwitch({
    Key? key,
    required this.currentMode,
    required this.isSelected,
  }) : super(key: key);

  @override
  State<SystemModeSwitch> createState() => _SystemModeSwitchState();
}

class _SystemModeSwitchState extends State<SystemModeSwitch> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
