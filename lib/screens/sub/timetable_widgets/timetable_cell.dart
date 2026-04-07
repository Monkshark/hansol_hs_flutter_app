import 'package:flutter/material.dart';

class TimetableCell extends StatelessWidget {
  final String subject;
  final bool isConflict;
  final bool isDark;
  final bool isToday;
  final Color? customColor;
  final VoidCallback? onLongPress;

  const TimetableCell({
    required this.subject,
    required this.isConflict,
    required this.isDark,
    this.isToday = false,
    this.customColor,
    this.onLongPress,
  });

  static const _lightPastels = [
    Color(0xFFDCE8F5), Color(0xFFD5ECD4), Color(0xFFF5DDD5),
    Color(0xFFE3D5F0), Color(0xFFF0E4D0), Color(0xFFD0ECE8),
    Color(0xFFF5E0E8), Color(0xFFE8E4D0), Color(0xFFD8E0F0),
    Color(0xFFE0F0D8), Color(0xFFF0D8D8), Color(0xFFD8F0F0),
  ];

  static const _darkPastels = [
    Color(0xFF2A3A4A), Color(0xFF2A3F2A), Color(0xFF4A3530),
    Color(0xFF3A2D48), Color(0xFF443D2D), Color(0xFF2A4240),
    Color(0xFF482D38), Color(0xFF3A382D), Color(0xFF303548),
    Color(0xFF354830), Color(0xFF483030), Color(0xFF304848),
  ];

  static const _textColors = [
    Color(0xFF4A6A8A), Color(0xFF4A7A4A), Color(0xFF8A5A4A),
    Color(0xFF6A4A8A), Color(0xFF7A6A4A), Color(0xFF4A7A75),
    Color(0xFF8A4A60), Color(0xFF6A654A), Color(0xFF4A508A),
    Color(0xFF5A7A4A), Color(0xFF8A4A4A), Color(0xFF4A7A8A),
  ];

  int _colorIndex(String s) => s.hashCode.abs() % _lightPastels.length;

  @override
  Widget build(BuildContext context) {
    if (subject.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1C22) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
        ),
      );
    }

    Color bg;
    Color textColor;

    if (customColor != null) {
      bg = isDark
          ? HSLColor.fromColor(customColor!).withLightness(0.15).withSaturation(0.3).toColor()
          : HSLColor.fromColor(customColor!).withLightness(0.92).withSaturation(0.4).toColor();
      textColor = isDark
          ? HSLColor.fromColor(customColor!).withLightness(0.75).toColor()
          : HSLColor.fromColor(customColor!).withLightness(0.35).toColor();
    } else {
      final idx = _colorIndex(subject);
      bg = isDark ? _darkPastels[idx] : _lightPastels[idx];
      textColor = isDark ? _lightPastels[idx] : _textColors[idx];
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: Text(
              subject,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
