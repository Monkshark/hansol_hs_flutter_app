import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../data/grade_manager.dart';

/// 성적 추이 그래프 위젯
///
/// - 시험별 과목 등급을 꺾은선 그래프로 표시
/// - Y축: 등급 (내신 1~5, 모의 1~9, 위가 1등급)
/// - X축: 시험 이름 (시간순)
/// - 과목별 필터 칩, 목표 등급 점선, 범례 포함
class GradeChart extends StatefulWidget {
  final List<Exam> exams;
  final Map<String, double> goals;
  final int maxRank;
  final ValueChanged<Map<String, double>>? onGoalsChanged;

  const GradeChart({
    super.key,
    required this.exams,
    this.goals = const {},
    this.maxRank = 9,
    this.onGoalsChanged,
  });

  @override
  State<GradeChart> createState() => _GradeChartState();
}

class _GradeChartState extends State<GradeChart> {
  late Set<String> _allSubjects;
  late Set<String> _visibleSubjects;
  // 0=등급, 1=점수(내신:원점수, 모의:표준점수), 2=백분위(모의만)
  int _chartMode = 0;

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
        if (score.rank != null || score.rawScore != null || score.standardScore != null) {
          _allSubjects.add(score.subject);
        }
      }
    }
    _visibleSubjects = Set<String>.from(_allSubjects);
  }

  /// 현재 시험 리스트가 모의고사인지 판별
  bool get _isMockExams {
    return widget.exams.any((e) => e.type == 'mock' || e.type == 'private_mock');
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
        // 차트 모드 토글
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (_isMockExams) ...[
                _buildModeChip('백���위', _chartMode == 2, isDark, () {
                  if (_chartMode != 2) setState(() => _chartMode = 2);
                }),
                const SizedBox(width: 6),
                _buildModeChip('표���점수', _chartMode == 1, isDark, () {
                  if (_chartMode != 1) setState(() => _chartMode = 1);
                }),
                const SizedBox(width: 6),
              ] else ...[
                _buildModeChip('원점수', _chartMode == 1, isDark, () {
                  if (_chartMode != 1) setState(() => _chartMode = 1);
                }),
                const SizedBox(width: 6),
              ],
              _buildModeChip('등급', _chartMode == 0, isDark, () {
                if (_chartMode != 0) setState(() => _chartMode = 0);
              }),
            ],
          ),
        ),
        const SizedBox(height: 6),

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
        if (_chartMode == 0)
          _buildRankChart(examsWithRanks, isDark)
        else
          _buildScoreChart(sortedExams, isDark),

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

        // 목표 등급 조절 UI (등급 모드에서만)
        if (_chartMode == 0 && widget.onGoalsChanged != null && _visibleSubjects.isNotEmpty)
          _buildGoalControls(isDark),
      ],
    );
  }

  Widget _buildModeChip(String label, bool selected, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.08))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? (isDark ? Colors.white38 : Colors.black26)
                : (isDark ? Colors.white12 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? (isDark ? Colors.white : Colors.black87)
                : (isDark ? Colors.white54 : Colors.black45),
          ),
        ),
      ),
    );
  }

  Widget _buildRankChart(List<Exam> examsWithRanks, bool isDark) {
    return SizedBox(
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

                const minExamSpacing = 80.0;
                const leftPad = 36.0;
                const rightPad = 20.0;
                final chartAreaWidth = constraints.maxWidth - leftPad - rightPad;
                final neededWidth = max(
                  chartAreaWidth,
                  (examsWithRanks.length - 1) * minExamSpacing + 0.0,
                );
                final totalWidth = neededWidth + leftPad + rightPad;

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

                final visibleGoals = <String, double>{};
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
                        maxRank: widget.maxRank,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildScoreChart(List<Exam> sortedExams, bool isDark) {
    final isMock = _isMockExams;

    final usePercentile = _chartMode == 2 && isMock;

    // 점수 데이터가 있는 시험만 필터
    final examsWithScores = sortedExams.where((e) {
      return e.scores.any((s) {
        final hasScore = usePercentile ? s.percentile != null
            : (isMock ? s.standardScore != null : s.rawScore != null);
        return hasScore && _visibleSubjects.contains(s.subject);
      });
    }).toList();

    return SizedBox(
      height: 250,
      child: examsWithScores.isEmpty
          ? Center(
              child: Text(
                '점수 데이터가 없습니다',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontSize: 14,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final examLabels = examsWithScores.map(_abbreviate).toList();

                const minExamSpacing = 80.0;
                const leftPad = 44.0;
                const rightPad = 20.0;
                final chartAreaWidth = constraints.maxWidth - leftPad - rightPad;
                final neededWidth = max(
                  chartAreaWidth,
                  (examsWithScores.length - 1) * minExamSpacing + 0.0,
                );
                final totalWidth = neededWidth + leftPad + rightPad;

                // 과목별 점수 데이터 수집
                final subjectData = <String, List<_ScoreDataPoint>>{};
                for (final subject in _visibleSubjects) {
                  final points = <_ScoreDataPoint>[];
                  for (var i = 0; i < examsWithScores.length; i++) {
                    final exam = examsWithScores[i];
                    final matches = exam.scores.where((s) => s.subject == subject);
                    final score = matches.isEmpty ? null : matches.first;
                    if (score != null) {
                      final value = usePercentile ? score.percentile
                          : (isMock ? score.standardScore : score.rawScore?.toDouble());
                      if (value != null) {
                        points.add(_ScoreDataPoint(i, value));
                      }
                    }
                  }
                  if (points.isNotEmpty) {
                    subjectData[subject] = points;
                  }
                }

                // min/max 자동 계산
                double minScore = double.infinity;
                double maxScore = double.negativeInfinity;
                for (final points in subjectData.values) {
                  for (final p in points) {
                    if (p.score < minScore) minScore = p.score;
                    if (p.score > maxScore) maxScore = p.score;
                  }
                }
                if (minScore == double.infinity) {
                  minScore = 0;
                  maxScore = 100;
                }
                // 여유 마진
                final range = maxScore - minScore;
                final margin = range < 10 ? 5.0 : range * 0.15;
                minScore = (minScore - margin).floorToDouble();
                maxScore = (maxScore + margin).ceilToDouble();
                if (minScore < 0) minScore = 0;
                if (!isMock && maxScore > 100) maxScore = 100;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalWidth,
                    height: 250,
                    child: CustomPaint(
                      painter: _ScoreChartPainter(
                        examLabels: examLabels,
                        examCount: examsWithScores.length,
                        subjectData: subjectData,
                        isDark: isDark,
                        textColor: isDark ? Colors.white70 : Colors.black87,
                        gridColor: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08),
                        leftPadding: leftPad,
                        rightPadding: rightPad,
                        minScore: minScore,
                        maxScore: maxScore,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildGoalControls(bool isDark) {
    // 보이는 과목 중 목표가 설정된 과목만
    final goalsToShow = <String, double>{};
    for (final subject in _visibleSubjects) {
      if (widget.goals.containsKey(subject)) {
        goalsToShow[subject] = widget.goals[subject]!;
      }
    }
    if (goalsToShow.isEmpty) return const SizedBox.shrink();

    final subTextColor = isDark ? Colors.white54 : Colors.black45;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '목표 등급',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subTextColor,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: goalsToShow.entries.map((entry) {
              final subject = entry.key;
              final rank = entry.value;
              final color = Color(GradeManager.getSubjectColor(subject));
              return _GoalChip(
                subject: subject,
                rank: rank,
                color: color,
                maxRank: widget.maxRank,
                isDark: isDark,
                onChanged: (newRank) {
                  final updated = Map<String, double>.from(widget.goals);
                  updated[subject] = newRank;
                  widget.onGoalsChanged?.call(updated);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String subject;
  final double rank;
  final Color color;
  final int maxRank;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _GoalChip({
    required this.subject,
    required this.rank,
    required this.color,
    required this.maxRank,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[100]!;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final canUp = rank > 1.0;
    final canDown = rank < maxRank;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$subject ${rank.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 11, color: textColor),
          ),
          const SizedBox(width: 4),
          _miniButton(
            icon: Icons.arrow_drop_up,
            enabled: canUp,
            onTap: canUp ? () => onChanged(((rank - 0.1) * 10).round() / 10) : null,
          ),
          _miniButton(
            icon: Icons.arrow_drop_down,
            enabled: canDown,
            onTap: canDown ? () => onChanged(((rank + 0.1) * 10).round() / 10) : null,
          ),
        ],
      ),
    );
  }

  Widget _miniButton({
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    final activeColor = isDark ? Colors.white70 : Colors.black87;
    final disabledColor = isDark ? Colors.white24 : Colors.black26;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? activeColor : disabledColor,
        ),
      ),
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
  final Map<String, double> goals;
  final bool isDark;
  final Color textColor;
  final Color gridColor;
  final double leftPadding;
  final double rightPadding;

  final int maxRank;

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
    this.maxRank = 9,
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
    for (var rank = 1; rank <= maxRank; rank++) {
      final y = chartTop + (rank - 1) / (maxRank - 1) * chartHeight;
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

    double rankToY(num rank) => chartTop + (rank - 1) / (maxRank - 1) * chartHeight;
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

class _ScoreDataPoint {
  final int examIndex;
  final double score;
  const _ScoreDataPoint(this.examIndex, this.score);
}

class _ScoreChartPainter extends CustomPainter {
  final List<String> examLabels;
  final int examCount;
  final Map<String, List<_ScoreDataPoint>> subjectData;
  final bool isDark;
  final Color textColor;
  final Color gridColor;
  final double leftPadding;
  final double rightPadding;
  final double minScore;
  final double maxScore;

  _ScoreChartPainter({
    required this.examLabels,
    required this.examCount,
    required this.subjectData,
    required this.isDark,
    required this.textColor,
    required this.gridColor,
    required this.leftPadding,
    required this.rightPadding,
    required this.minScore,
    required this.maxScore,
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

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final textStyle = ui.TextStyle(
      color: textColor,
      fontSize: 11,
    );

    // Y축 그리드 라인 수 결정 (4~6개)
    final scoreRange = maxScore - minScore;
    final rawStep = scoreRange / 5;
    // 깔끔한 간격으로 반올림
    final step = rawStep <= 5
        ? 5.0
        : rawStep <= 10
            ? 10.0
            : rawStep <= 20
                ? 20.0
                : (rawStep / 10).ceil() * 10.0;

    final firstTick = (minScore / step).ceil() * step;

    for (var tick = firstTick; tick <= maxScore; tick += step) {
      final y = _scoreToY(tick, chartTop, chartHeight);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final label = tick == tick.roundToDouble() ? '${tick.round()}' : tick.toStringAsFixed(1);
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: TextAlign.right,
        fontSize: 11,
      ))
        ..pushStyle(textStyle)
        ..addText(label);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: 34));
      canvas.drawParagraph(paragraph, Offset(chartLeft - 38, y - 7));
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

    double indexToX(int index) => examCount == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + index / (examCount - 1) * chartWidth;

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
          final y = _scoreToY(points[i].score, chartTop, chartHeight);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        canvas.drawPath(path, linePaint);
      }

      // 점 + 점수 텍스트
      for (final p in points) {
        final x = indexToX(p.examIndex);
        final y = _scoreToY(p.score, chartTop, chartHeight);

        canvas.drawCircle(Offset(x, y), 5.5, dotBorderPaint);
        canvas.drawCircle(Offset(x, y), 4, dotPaint);

        // 점수 표시
        final scoreLabel = p.score == p.score.roundToDouble()
            ? '${p.score.round()}'
            : p.score.toStringAsFixed(1);
        final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.center,
          fontSize: 9,
        ))
          ..pushStyle(ui.TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 9,
            fontWeight: ui.FontWeight.bold,
          ))
          ..addText(scoreLabel);
        final paragraph = builder.build()
          ..layout(const ui.ParagraphConstraints(width: 30));
        canvas.drawParagraph(paragraph, Offset(x - 15, y - 18));
      }
    }
  }

  /// 점수 -> Y좌표 (높은 점수가 위쪽)
  double _scoreToY(double score, double chartTop, double chartHeight) {
    final ratio = (score - minScore) / (maxScore - minScore);
    return chartTop + (1.0 - ratio) * chartHeight;
  }

  @override
  bool shouldRepaint(covariant _ScoreChartPainter oldDelegate) {
    return oldDelegate.examCount != examCount ||
        oldDelegate.subjectData != subjectData ||
        oldDelegate.isDark != isDark ||
        oldDelegate.minScore != minScore ||
        oldDelegate.maxScore != maxScore;
  }
}
