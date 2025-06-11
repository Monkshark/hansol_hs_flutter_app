import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/data/device.dart';

class SubjectCard extends StatefulWidget {
  final String subjectName;
  final int classNumber;
  final bool checked;
  final ValueChanged<bool>? onCheck;

  const SubjectCard({
    Key? key,
    required this.subjectName,
    required this.classNumber,
    this.checked = false,
    this.onCheck,
  }) : super(key: key);

  @override
  _SubjectCardState createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    if (widget.checked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(SubjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.checked != oldWidget.checked) {
      if (widget.checked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onCheck != null) {
      widget.onCheck!(!widget.checked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(22),
      color: Colors.white,
      child: Container(
        width: Device.getWidth(80),
        height: Device.getHeight(15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${widget.subjectName}\n${widget.classNumber}반',
                style: TextStyle(
                  fontSize: Device.getWidth(3.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            GestureDetector(
              onTap: _handleTap,
              child: CustomPaint(
                size: const Size(24, 24),
                painter: CheckBoxPainter(_animation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckBoxPainter extends CustomPainter {
  final Animation<double> animation;

  CheckBoxPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(4));
    canvas.drawRRect(rrect, paint);

    if (animation.value > 0) {
      final checkPaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();

      final checkSize = size.width * 0.6;
      final startX = size.width * 0.2;
      final startY = size.height * 0.5;
      final midX = startX + checkSize * 0.3;
      final midY = startY + checkSize * 0.3;
      final endX = startX + checkSize;
      final endY = startY - checkSize * 0.3;

      final firstSegmentLength =
          sqrt(pow(midX - startX, 2) + pow(midY - startY, 2));
      final secondSegmentLength =
          sqrt(pow(endX - midX, 2) + pow(endY - midY, 2));
      final totalLength = firstSegmentLength + secondSegmentLength;
      final dashLength = totalLength * animation.value;

      if (dashLength <= firstSegmentLength) {
        final t = dashLength / firstSegmentLength;
        final x = startX + t * (midX - startX);
        final y = startY + t * (midY - startY);
        path.moveTo(startX, startY);
        path.lineTo(x, y);
      } else {
        path.moveTo(startX, startY);
        path.lineTo(midX, midY);
        final remainingLength = dashLength - firstSegmentLength;
        if (remainingLength > 0) {
          final t = remainingLength / secondSegmentLength;
          final x = midX + t * (endX - midX);
          final y = midY + t * (endY - midY);
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
