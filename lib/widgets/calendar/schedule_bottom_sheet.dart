import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hansol_high_school/data/local_database.dart';
import 'package:hansol_high_school/data/schedule_data.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:intl/intl.dart';

/// 일정 만들기 바텀시트
/// - 시작일/종료일 DatePicker (같으면 하루, 다르면 연속)
/// - 색상 6종 선택
class ScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onScheduleCreated;

  const ScheduleBottomSheet({
    required this.selectedDate,
    required this.onScheduleCreated,
    Key? key,
  }) : super(key: key);

  @override
  State<ScheduleBottomSheet> createState() => _ScheduleBottomSheetState();
}

class _ScheduleBottomSheetState extends State<ScheduleBottomSheet> {
  final TextEditingController contentController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;

  final List<Color> _colors = [
    const Color(0xFF3F72AF),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFFEF5350),
    const Color(0xFF9C27B0),
    const Color(0xFF00BCD4),
  ];
  int _selectedColorIdx = 0;
  Color _customColor = const Color(0xFFE91E63);

  @override
  void initState() {
    super.initState();
    _startDate = widget.selectedDate;
    _endDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);
    final isMultiDay = !_startDate.isAtSameMomentAs(_endDate);

    return SafeArea(
      child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2028) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 36, height: 4, margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              Text('일정 만들기', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
              const SizedBox(height: 16),

              // 내용
              TextField(
                controller: contentController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: '일정 내용을 입력하세요',
                  hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                  filled: true,
                  fillColor: fillColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 날짜 선택
              Row(
                children: [
                  Expanded(child: _datePicker('시작일', _startDate, (d) => setState(() {
                    _startDate = d;
                    if (_endDate.isBefore(_startDate)) _endDate = _startDate;
                  }))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('~', style: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 16)),
                  ),
                  Expanded(child: _datePicker('종료일', _endDate, (d) => setState(() => _endDate = d))),
                ],
              ),
              if (isMultiDay)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${_endDate.difference(_startDate).inDays + 1}일간',
                    style: TextStyle(fontSize: 12, color: AppColors.theme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),

              // 색상
              Text('색상', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.darkGreyColor)),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(_colors.length, (i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColorIdx = i),
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _colors[i],
                          shape: BoxShape.circle,
                          border: _selectedColorIdx == i
                              ? Border.all(color: textColor ?? Colors.white, width: 2.5)
                              : null,
                        ),
                        child: _selectedColorIdx == i
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                    ),
                  )),
                  GestureDetector(
                    onTap: () => _showColorPicker(textColor),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(colors: [
                          Color(0xFFFF0000), Color(0xFFFF9800), Color(0xFFFFEB3B),
                          Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0), Color(0xFFFF0000),
                        ]),
                        border: _selectedColorIdx == _colors.length - 1 && _colors.last == _customColor
                            ? Border.all(color: textColor ?? Colors.white, width: 2.5)
                            : null,
                      ),
                      child: const Icon(Icons.colorize, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 버튼
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _colors[_selectedColorIdx],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('추가'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _datePicker(String label, DateTime date, ValueChanged<DateTime> onPicked) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: AppColors.theme.darkGreyColor),
            const SizedBox(width: 8),
            Text(
              DateFormat('M/d (E)', 'ko_KR').format(date),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(Color? textColor) {
    double hue = HSLColor.fromColor(_customColor).hue;
    double lightness = HSLColor.fromColor(_customColor).lightness.clamp(0.2, 0.8);

    String? _dragZone; // 'inner' or 'outer' — 드래그 시작 영역 잠금

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final previewColor = HSLColor.fromAHSL(1, hue, 0.7, lightness).toColor();
          const size = 220.0;
          const center = Offset(size / 2, size / 2);
          const radius = size / 2;
          const innerRadius = radius * 0.38;

          void startDrag(Offset pos) {
            final dx = pos.dx - center.dx;
            final dy = pos.dy - center.dy;
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist > radius) return;
            _dragZone = dist <= innerRadius ? 'inner' : 'outer';
          }

          void updateFromPos(Offset pos) {
            final dx = pos.dx - center.dx;
            final dy = pos.dy - center.dy;
            final dist = math.sqrt(dx * dx + dy * dy);
            if (dist > radius) return;

            if (_dragZone == 'inner') {
              setDialogState(() {
                lightness = (1 - (pos.dy / size)).clamp(0.2, 0.8);
              });
            } else if (_dragZone == 'outer') {
              setDialogState(() {
                hue = (180 / math.pi * math.atan2(dy, dx) + 360) % 360;
              });
            }
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
                      color: previewColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('미리보기',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white))),
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
                        painter: _CircleColorPainter(selectedHue: hue, lightness: lightness),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('취소', style: TextStyle(color: AppColors.theme.darkGreyColor)),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _customColor = previewColor;
                            // 기존 커스텀 색 제거 후 추가
                            _colors.removeWhere((c) => !const [
                              Color(0xFF3F72AF), Color(0xFF4CAF50), Color(0xFFFF9800),
                              Color(0xFFEF5350), Color(0xFF9C27B0), Color(0xFF00BCD4),
                            ].contains(c));
                            _colors.add(_customColor);
                            _selectedColorIdx = _colors.length - 1;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: previewColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('선택'),
                      )),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Future<void> _onSave() async {
    if (contentController.text.trim().isEmpty) return;

    final dateStr = _startDate.toIso8601String().substring(0, 10);
    final isMultiDay = !_startDate.isAtSameMomentAs(_endDate);
    final endDateStr = isMultiDay ? _endDate.toIso8601String().substring(0, 10) : null;

    final schedule = Schedule(
      startTime: -1,
      endTime: -1,
      content: contentController.text.trim(),
      date: dateStr,
      endDate: endDateStr,
      color: _colors[_selectedColorIdx].value,
    );

    await GetIt.I<LocalDataBase>().insertSchedule(schedule);
    Navigator.of(context).pop();
    widget.onScheduleCreated();
  }
}

class _CircleColorPainter extends CustomPainter {
  final double selectedHue;
  final double lightness;
  _CircleColorPainter({required this.selectedHue, required this.lightness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerR = radius * 0.38;

    // 외곽 색상환
    for (double angle = 0; angle < 360; angle += 1) {
      final paint = Paint()
        ..color = HSLColor.fromAHSL(1, angle, 0.7, lightness).toColor()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.35;

      final rad = angle * math.pi / 180;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.82),
        rad, math.pi / 180 + 0.02, false, paint,
      );
    }

    // 중앙 밝기 그라데이션 (위=밝게, 아래=어둡게)
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

    // 밝기 인디케이터 (가로 선)
    final lY = center.dy - innerR + (1 - lightness) * innerR * 2;
    canvas.drawLine(
      Offset(center.dx - innerR * 0.6, lY),
      Offset(center.dx + innerR * 0.6, lY),
      Paint()..color = Colors.white..strokeWidth = 2..strokeCap = StrokeCap.round,
    );

    // 색상환 선택 표시
    final indicatorRad = selectedHue * math.pi / 180;
    final ix = center.dx + radius * 0.82 * math.cos(indicatorRad);
    final iy = center.dy + radius * 0.82 * math.sin(indicatorRad);
    canvas.drawCircle(Offset(ix, iy), 8, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(covariant _CircleColorPainter old) =>
      old.selectedHue != selectedHue || old.lightness != lightness;
}
