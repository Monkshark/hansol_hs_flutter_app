import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class TimetableColorPickerDialog extends StatefulWidget {
  final String subjectName;
  final Color? currentColor;
  final ValueChanged<Color> onColorSelected;

  const TimetableColorPickerDialog({
    required this.subjectName,
    required this.currentColor,
    required this.onColorSelected,
  });

  @override
  State<TimetableColorPickerDialog> createState() => TimetableColorPickerDialogState();
}

class TimetableColorPickerDialogState extends State<TimetableColorPickerDialog> {
  double _hue = 0;
  double _lightness = 0.5;

  @override
  void initState() {
    super.initState();
    if (widget.currentColor != null) {
      final hsl = HSLColor.fromColor(widget.currentColor!);
      _hue = hsl.hue;
      _lightness = hsl.lightness.clamp(0.2, 0.8);
    }
  }

  Color get _selectedColor => HSLColor.fromAHSL(1, _hue, 0.7, _lightness).toColor();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final previewBg = isDark
        ? HSLColor.fromAHSL(1, _hue, 0.4, 0.15).toColor()
        : _selectedColor;
    final previewText = isDark
        ? HSLColor.fromAHSL(1, _hue, 0.7, 0.75).toColor()
        : HSLColor.fromAHSL(1, _hue, 0.7, 0.35).toColor();

    const size = 220.0;
    const center = Offset(size / 2, size / 2);
    const radius = size / 2;
    const innerR = radius * 0.38;

    String? _dragZone;

    void startDrag(Offset pos) {
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radius) return;
      _dragZone = dist <= innerR ? 'inner' : 'outer';
    }

    void updateFromPos(Offset pos) {
      final dx = pos.dx - center.dx;
      final dy = pos.dy - center.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist > radius) return;
      setState(() {
        if (_dragZone == 'inner') {
          _lightness = (1 - (pos.dy / size)).clamp(0.2, 0.8);
        } else if (_dragZone == 'outer') {
          _hue = (180 / math.pi * math.atan2(dy, dx) + 360) % 360;
        }
      });
    }

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E2028) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Text(widget.subjectName, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: previewText))),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: size, height: size,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) { startDrag(d.localPosition); updateFromPos(d.localPosition); },
                onPanUpdate: (d) => updateFromPos(d.localPosition),
                onPanEnd: (_) => _dragZone = null,
                onTapDown: (d) { startDrag(d.localPosition); updateFromPos(d.localPosition); },
                child: CustomPaint(
                  size: const Size(size, size),
                  painter: TimetableColorPainter(selectedHue: _hue, lightness: _lightness),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.theme.darkGreyColor),
                      ),
                    ),
                    child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onColorSelected(_selectedColor);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('확인'),
                  ),
                ),
              ],
            ),
            if (widget.currentColor != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    widget.onColorSelected(const Color(0x00000000));
                    Navigator.of(context).pop();
                  },
                  child: Text('기본 색상으로 초기화', style: TextStyle(fontSize: 12, color: AppColors.theme.darkGreyColor)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TimetableColorPainter extends CustomPainter {
  final double selectedHue;
  final double lightness;
  TimetableColorPainter({required this.selectedHue, required this.lightness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerR = radius * 0.38;

    for (double angle = 0; angle < 360; angle += 1) {
      final paint = Paint()
        ..color = HSLColor.fromAHSL(1, angle, 0.7, lightness).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.35;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.82),
        angle * math.pi / 180, math.pi / 180 + 0.02, false, paint,
      );
    }

    final selectedColor = HSLColor.fromAHSL(1, selectedHue, 0.7, 0.5);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        selectedColor.withLightness(0.8).toColor(),
        selectedColor.withLightness(0.5).toColor(),
        selectedColor.withLightness(0.2).toColor(),
      ],
    );
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: innerR)));
    final rect = Rect.fromCircle(center: center, radius: innerR);
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    canvas.restore();

    final lY = center.dy - innerR + (1 - lightness) * innerR * 2;
    canvas.drawLine(
      Offset(center.dx - innerR * 0.6, lY),
      Offset(center.dx + innerR * 0.6, lY),
      Paint()..color = Colors.white..strokeWidth = 2..strokeCap = StrokeCap.round,
    );

    final indicatorRad = selectedHue * math.pi / 180;
    final ix = center.dx + radius * 0.82 * math.cos(indicatorRad);
    final iy = center.dy + radius * 0.82 * math.sin(indicatorRad);
    canvas.drawCircle(Offset(ix, iy), 8, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant TimetableColorPainter old) =>
      old.selectedHue != selectedHue || old.lightness != lightness;
}
