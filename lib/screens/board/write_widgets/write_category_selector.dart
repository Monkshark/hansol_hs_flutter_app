import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/data/board_categories.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class WriteCategorySelector extends StatelessWidget {
  final List<String> categoryKeys;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const WriteCategorySelector({
    super.key,
    required this.categoryKeys,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l.write_category, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.theme.primaryColor)),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categoryKeys.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = categoryKeys[index];
              final selected = selectedCategory == cat;
              return GestureDetector(
                onTap: () => onCategoryChanged(cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.theme.primaryColor
                        : (isDark ? const Color(0xFF252830) : const Color(0xFFF0F0F0)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    BoardCategories.localizedName(l, cat),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.theme.darkGreyColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
