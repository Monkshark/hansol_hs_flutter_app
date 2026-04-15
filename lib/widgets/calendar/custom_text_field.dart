import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final bool isTime;
  final FormFieldSetter<String> onSaved;
  final FormFieldValidator<String> validator;
  final TextEditingController controller;
  final VoidCallback? onTap;

  const CustomTextField({
    required this.label,
    required this.isTime,
    required this.onSaved,
    required this.validator,
    required this.controller,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.theme.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          onSaved: onSaved,
          validator: validator,
          cursorColor: AppColors.theme.primaryColor,
          maxLines: isTime ? 1 : null,
          readOnly: isTime,
          onTap: onTap,
          keyboardType: isTime ? TextInputType.none : TextInputType.multiline,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: isTime ? Icon(Icons.access_time, size: 20, color: AppColors.theme.darkGreyColor) : null,
          ),
        ),
      ],
    );
  }
}
