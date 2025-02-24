import 'package:flutter/material.dart';
import 'package:hansol_high_school/Data/device.dart';

enum ThemeType { light, system, dark }

class ThemeModeButtons extends StatefulWidget {
  final Function(ThemeType) onModeChanged;
  final ThemeType initialMode;

  const ThemeModeButtons({
    Key? key,
    required this.onModeChanged,
    required this.initialMode,
  }) : super(key: key);

  @override
  State<ThemeModeButtons> createState() => _ThemeModeButtonsState();
}

class _ThemeModeButtonsState extends State<ThemeModeButtons> {
  late ThemeType selectedMode;

  @override
  void initState() {
    super.initState();
    selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildModeButton(
          type: ThemeType.light,
          icon: Icons.light_mode,
          label: "라이트 모드",
          selectedIconColor: Color(0xFFFF9500),
        ),
        _buildModeButton(
          type: ThemeType.dark,
          icon: Icons.dark_mode,
          label: "다크 모드",
          selectedIconColor: Color(0xFF21005D),
        ),
        _buildModeButton(
          type: ThemeType.system,
          icon: Icons.brightness_medium_sharp,
          label: "시스템 모드",
          selectedIconColor: Color(0xFF34C759),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required ThemeType type,
    required IconData icon,
    required String label,
    required Color selectedIconColor,
  }) {
    var isSelected = selectedMode == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMode = type;
        });
        widget.onModeChanged(type);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: isSelected ? Color(0xFFE5E5EA) : Colors.white,
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
                  color: isSelected ? selectedIconColor : Color(0xFF8E8E93),
                  borderRadius: BorderRadius.circular(Device.getWidth(5)),
                ),
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: Device.getWidth(1),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: Device.getWidth(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
