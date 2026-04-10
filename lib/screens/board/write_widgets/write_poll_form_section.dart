import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

/// 글쓰기 화면의 투표 폼
class WritePollFormSection extends StatelessWidget {
  final List<TextEditingController> pollControllers;
  final void Function(int index) onRemoveOption;
  final VoidCallback onAddOption;
  final bool isDark;
  final Color? textColor;
  final Color fillColor;

  const WritePollFormSection({
    super.key,
    required this.pollControllers,
    required this.onRemoveOption,
    required this.onAddOption,
    required this.isDark,
    required this.textColor,
    required this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.secondaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(pollControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.theme.secondaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(child: Text(
                      '${i + 1}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.theme.secondaryColor),
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: pollControllers[i],
                      style: TextStyle(fontSize: 14, color: textColor),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.write_pollOptionHint(i + 1),
                        hintStyle: TextStyle(color: AppColors.theme.darkGreyColor, fontSize: 14),
                        filled: true,
                        fillColor: fillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                  if (i >= 2)
                    GestureDetector(
                      onTap: () => onRemoveOption(i),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.close, size: 18, color: AppColors.theme.darkGreyColor),
                      ),
                    ),
                ],
              ),
            );
          }),
          if (pollControllers.length < 6)
            GestureDetector(
              onTap: onAddOption,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 16, color: AppColors.theme.secondaryColor),
                    const SizedBox(width: 4),
                    Text(AppLocalizations.of(context)!.write_pollAddOption, style: TextStyle(
                      fontSize: 13, color: AppColors.theme.secondaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
