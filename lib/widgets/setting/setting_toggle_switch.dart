import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class SettingToggleSwitch extends StatefulWidget {
  final Function(bool value) onChanged;
  final bool value;
  final double trackWidth;
  final double trackHeight;
  final double toggleWidth;
  final double toggleHeight;
  final Color toggleActiveColor;
  final Color toggleInActiveColor;
  final Color trackInActiveColor;
  final Color trackActiveColor;

  SettingToggleSwitch({
    Key? key,
    required this.onChanged,
    required this.value,
    this.trackHeight = 10.0,
    this.trackWidth = 40.0,
    this.toggleWidth = 20.0,
    this.toggleHeight = 20.0,
    this.trackActiveColor = const Color(0xffcccccc),
    this.trackInActiveColor = const Color(0xffcccccc),
    Color? toggleActiveColor,
    this.toggleInActiveColor = const Color(0xffcccccc),
  })  : toggleActiveColor = toggleActiveColor ?? AppColors.theme.primaryColor,
        super(key: key);

  @override
  State<SettingToggleSwitch> createState() => _SettingToggleSwitchState();
}

class _SettingToggleSwitchState extends State<SettingToggleSwitch> {
  bool _isSwitched = false;

  @override
  void initState() {
    super.initState();
    _isSwitched = widget.value;
  }

  void _toggleSwitch() {
    setState(() {
      _isSwitched = !_isSwitched;
      widget.onChanged(_isSwitched);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleSwitch,
      child: SizedBox(
        width: widget.trackWidth,
        height: widget.toggleHeight > widget.trackHeight
            ? widget.toggleHeight
            : widget.trackHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.trackWidth,
              height: widget.trackHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: _isSwitched
                    ? widget.trackActiveColor
                    : widget.trackInActiveColor,
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              left: _isSwitched ? widget.trackWidth - widget.toggleWidth : 0.0,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  setState(() {
                    double newPosition = details.localPosition.dx;
                    if (newPosition < 0) {
                      newPosition = 0;
                    } else if (newPosition >
                        widget.trackWidth - widget.toggleWidth) {
                      newPosition = widget.trackWidth - widget.toggleWidth;
                    }
                    _isSwitched = newPosition >
                        (widget.trackWidth - widget.toggleWidth) / 2;
                    widget.onChanged(_isSwitched);
                  });
                },
                child: Container(
                  width: widget.toggleWidth,
                  height: widget.toggleHeight,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSwitched
                        ? widget.toggleActiveColor
                        : widget.toggleInActiveColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
