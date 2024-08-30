import 'package:flutter/material.dart';
import 'package:hansol_high_school/Styles/app_colors.dart';

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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.color.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: controller,
          onSaved: onSaved,
          validator: validator,
          cursorColor: Colors.grey,
          maxLines: isTime ? 1 : null,
          readOnly: isTime,
          onTap: onTap,
          keyboardType: isTime ? TextInputType.none : TextInputType.multiline,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            suffixText: isTime ? '' : null,
          ),
        ),
      ],
    );
  }
}
