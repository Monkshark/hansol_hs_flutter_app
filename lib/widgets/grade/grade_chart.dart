import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/grade_manager.dart';

/// 성적 추이 그래프 위젯
///
/// - 시험별 과목 등급을 꺾은선 그래프로 표시
/// - Y축: 등급 (1~9, 위가 1등급)
/// - X축: 시험 이름 (시간순)
/// - 과목별 필터 칩, 목표 등급 점선, 범례 포함
class GradeChart extends StatefulWidget {
  final List<Exam> exams;
  final Map<String, int> goals;

  const GradeChart({
    super.key,
    required this.exams,
    this.goals = const {},
  });

  @override
  State<GradeChart> createState() => _GradeChartState();
}

class _GradeChartState extends State<GradeChart> {
  late Set<String> _allSubjects;
  late Set<String> _visibleSubjects;

  @override
  void initState() {
    super.initState();
    _initSubjects();
  }

  @override
  void didUpdateWidget(covariant GradeChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exams != widget.exams) {
      _initSubjects();
    }
  }

  void _initSubjects() {
    _allSubjects = <String>{};
    for (final exam in widget.exams) {
      for (final score in exam.scores) {
        if (score.rank != null) {
          _allSubjects.add(score.subject);
        }
      }
    }
    _visibleSubjects = Set<String>.from(_allSubjects);
  }

  /// 시험 이름 축약
  String _abbreviate(Exam exam) {
    switch (exam.type) {
      case 'midterm':
        return '${exam.semester}학기 중간';
      case 'final':
        return '${exam.semester}학기 기말';
      case 'mock':
        return '${exam.mockLabel ?? ""} 모의';
      case 'private_mock':
        return exam.mockLabel ?? '사설';
      default:
        return '시험';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedExams = List<Exam>.from(widget.exams)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // 등급 데이터가 있는 시험만
    final examsWithRanks = sortedExams.where((e) {
      return e.scores.any((s) => s.rank != null && _visibleSubjects.contains(s.subject));
    }).toList();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 과목 필터 칩
        if (_allSubjects.isNotEmpty)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _allSubjects.map((subject) {
                final color = Color(GradeManager.getSubjectColor(subject));
                final selected = _visibleSubjects.contains(subject);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      subject,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _visibleSubjects.add(subject);
                        } else {
                          _visibleSubjects.remove(subject);
                        }
                      });
                    },
                    selectedColor: color,
                    checkmarkColor: Colors.white,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 8),

        // 차트 영역
        SizedBox(
          height: 250,
          child: examsWithRanks.isEmpty
              ? Center(
                  child: Text(
                    '데이터가 없습니다',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 14,
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final examLabels = examsWithRanks.map(_abbreviate).toList();

                    // 시험이 많으면 스크롤
                    const minExamSpacing = 80.0;
                    const leftPad = 36.0;
                    const rightPad = 20.0;
                    final chartAreaWidth = constraints.maxWidth - leftPad - rightPad;
                    final neededWidth = max(
                      chartAreaWidth,
                      (examsWithRanks.length - 1) * minExamSpacing + 0.0,
                    );
                    final totalWidth = neededWidth + leftPad + rightPad;

                    // 과목별 데이터 수집: subject -> List<(examIndex, rank)>
                    final subjectData = <String, List<_DataPoint>>{};
                    for (final subject in _visibleSubjects) {
                      final points = <_DataPoint>[];
                      for (var i = 0; i < examsWithRanks.length; i++) {
                        final exam = examsWithRanks[i];
                        final matches = exam.scores.where((s) => s.subject == subject);
                        final score = matches.isEmpty ? null : matches.first;
                        if (score?.rank != null) {
                          points.add(_DataPoint(i, score!.rank!));
                        }
                      }
                      if (points.isNotEmpty) {
                        subjectData[subject] = points;
                      }
                    }

                    // 목표 등급 (보이는 과목만)
                    final visibleGoals = <String, int>{};
                    for (final entry in widget.goals.entries) {
                      if (_visibleSubjects.contains(entry.key)) {
                        visibleGoals[entry.key] = entry.value;
                      }
                    }

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: totalWidth,
                        height: 250,
                        child: CustomPaint(
                          painter: _GradeChartPainter(
                            examLabels: examLabels,
                            examCount: examsWithRanks.length,
                            subjectData: subjectData,
                            goals: visibleGoals,
                            isDark: isDark,
                            textColor: isDark ? Colors.white70 : Colors.black87,
                            gridColor: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.08),
                            leftPadding: leftPad,
                            rightPadding: rightPad,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        // 범례
        if (_visibleSubjects.isNotEmpty && examsWithRanks.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 4,
              children: _visibleSubjects.map((subject) {
                final color = Color(GradeManager.getSubjectColor(subject));
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subject,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _DataPoint {
  final int examIndex;
  final int rank;
  const _DataPoint(this.examIndex, this.rank);
}

class _GradeChartPainter extends CustomPainter {
  final List<String> examLabels;
  final int examCount;
  final Map<String, List<_DataPoint>> subjectData;
  final Map<String, int> goals;
  final bool isDark;
  final Color textColor;
  final Color gridColor;
  final double leftPadding;
  final double rightPadding;

  _GradeChartPainter({
    required this.examLabels,
    required this.examCount,
    required this.subjectData,
    required this.goals,
    required this.isDark,
    required this.textColor,
    required this.gridColor,
    required this.leftPadding,
    required this.rightPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 12.0;
    const bottomPad = 32.0;
    final chartLeft = leftPadding;
    final chartRight = size.width - rightPadding;
    const chartTop = topPad;
    final chartBottom = size.height - bottomPad;
    final chartHeight = chartBottom - chartTop;
    final chartWidth = chartRight - chartLeft;

    // Y축: 등급 1~9 (1이 위)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: 11,
    );

    // Y축 그리드 + 레이블
    for (var rank = 1; rank <= 9; rank++) {
      final y = chartTop + (rank - 1) / 8 * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.right,
        fontSize: 11,
      ))
        ..pushStyle(textStyle)
        ..addText('$rank');
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 24));
      canvas.drawParagraph(paragraph, Offset(chartLeft - 28, y - 7));
    }

    // X축 레이블
    for (var i = 0; i < examCount; i++) {
      final x = examCount == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + i / (examCount - 1) * chartWidth;

      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 10,
        maxLines: 1,
        ellipsis: '..',
      ))
        ..pushStyle(ui.TextStyle(color: textColor, fontSize: 10))
        ..addText(examLabels[i]);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 70));
      canvas.drawParagraph(paragraph, Offset(x - 35, chartBottom + 6));
    }

    double rankToY(int rank) => chartTop + (rank - 1) / 8 * chartHeight;
    double indexToX(int index) => examCount == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + index / (examCount - 1) * chartWidth;

    // 목표 점선
    for (final entry in goals.entries) {
      final color = Color(GradeManager.getSubjectColor(entry.key));
      final y = rankToY(entry.value);
      _drawDashedLine(
        canvas,
        Offset(chartLeft, y),
        Offset(chartRight, y),
        Paint()
          ..color = color.withValues(alpha: 0.4)
          ..strokeWidth = 1.2,
        dashWidth: 6,
        gapWidth: 4,
      );
    }

    // 과목별 라인 + 데이터 포인트
    for (final entry in subjectData.entries) {
      final subject = entry.key;
      final points = entry.value;
      final color = Color(GradeManager.getSubjectColor(subject));

      if (points.isEmpty) continue;

      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final dotBorderPaint = Paint()
        ..color = isDark ? Colors.black : Colors.white
        ..style = PaintingStyle.fill;

      // 선 그리기
      if (points.length > 1) {
        final path = Path();
        for (var i = 0; i < points.length; i++) {
          final x = indexToX(points[i].examIndex);
          final y = rankToY(points[i].rank);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, linePaint);
      }

      // 점 + 등급 텍스트
      for (final p in points) {
        final x = indexToX(p.examIndex);
        final y = rankToY(p.rank);

        // 흰색/검은색 배경 원
        canvas.drawCircle(Offset(x, y), 5.5, dotBorderPaint);
        // 색상 원
        canvas.drawCircle(Offset(x, y), 4, dotPaint);

        // 등급 숫자
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 9,
        ))
          ..pushStyle(ui.TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 9,
            fontWeight: ui.FontWeight.bold,
          ))
          ..addText('${p.rank}');
        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 20));
        canvas.drawParagraph(paragraph, Offset(x - 10, y - 18));
      }
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 5,
    double gapWidth = 3,
  }) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final totalLength = sqrt(dx * dx + dy * dy);
    final ux = dx / totalLength;
    final uy = dy / totalLength;

    var drawn = 0.0;
    var drawing = true;
    while (drawn < totalLength) {
      final segLen = drawing ? dashWidth : gapWidth;
      final segEnd = min(drawn + segLen, totalLength);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + ux * drawn, start.dy + uy * drawn),
          Offset(start.dx + ux * segEnd, start.dy + uy * segEnd),
          paint,
        );
      }
      drawn = segEnd;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _GradeChartPainter oldDelegate) {
    return oldDelegate.examCount != examCount ||
        oldDelegate.subjectData != subjectData ||
        oldDelegate.goals != goals ||
        oldDelegate.isDark != isDark;
  }
}
