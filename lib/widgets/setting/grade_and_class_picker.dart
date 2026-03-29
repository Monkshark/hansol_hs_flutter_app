import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class GradeAndClassPickerDialog extends StatefulWidget {
  final int initialGrade;
  final int initialClass;
  final int classCount;

  const GradeAndClassPickerDialog({
    Key? key,
    required this.initialGrade,
    required this.initialClass,
    required this.classCount,
  }) : super(key: key);

  @override
  State<GradeAndClassPickerDialog> createState() =>
      _GradeAndClassPickerDialogState();
}

class _GradeAndClassPickerDialogState extends State<GradeAndClassPickerDialog> {
  late FixedExtentScrollController _gradeController;
  late FixedExtentScrollController _classController;
  late int selectedGrade;
  late int selectedClass;

  @override
  void initState() {
    super.initState();
    selectedGrade = widget.initialGrade;
    selectedClass = widget.initialClass;
    _gradeController = FixedExtentScrollController(initialItem: selectedGrade - 1);
    _classController = FixedExtentScrollController(initialItem: selectedClass - 1);
  }

  @override
  void dispose() {
    _gradeController.dispose();
    _classController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2028) : Colors.white;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '학년 · 반 설정',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // 학년 휠
                  Expanded(
                    child: _buildWheel(
                      controller: _gradeController,
                      count: 3,
                      label: '학년',
                      onChanged: (i) => selectedGrade = i + 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('·', style: TextStyle(fontSize: 24, color: AppColors.theme.darkGreyColor)),
                  ),
                  // 반 휠
                  Expanded(
                    child: _buildWheel(
                      controller: _classController,
                      count: widget.classCount,
                      label: '반',
                      onChanged: (i) => selectedClass = i + 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop([selectedGrade, selectedClass]),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('확인', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int count,
    required String label,
    required ValueChanged<int> onChanged,
  }) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return CupertinoPicker(
      scrollController: controller,
      itemExtent: 40,
      diameterRatio: 1.2,
      selectionOverlay: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: AppColors.theme.primaryColor.withAlpha(80)),
          ),
        ),
      ),
      onSelectedItemChanged: onChanged,
      children: List.generate(count, (i) {
        return Center(
          child: Text(
            '${i + 1}$label',
            style: TextStyle(fontSize: 18, color: textColor),
          ),
        );
      }),
    );
  }
}
