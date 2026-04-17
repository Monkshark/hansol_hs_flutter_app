import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class GradeDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;
  final Color fillColor;

  const GradeDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    required this.fillColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(itemLabel(v), style: const TextStyle(fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }
}

class GradeMiniDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final Color fillColor;

  const GradeMiniDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.fillColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: items.contains(value) ? value : null,
            isExpanded: true,
            isDense: true,
            alignment: Alignment.center,
            hint: Text('-', style: TextStyle(fontSize: 13, color: AppColors.theme.darkGreyColor), textAlign: TextAlign.center),
            items: items.map((e) => DropdownMenuItem<T>(
              value: e,
              alignment: Alignment.center,
              child: Text('$e', style: const TextStyle(fontSize: 13)),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class GradeScoreField extends StatelessWidget {
  final TextEditingController controller;
  final Color fillColor;
  final bool isInt;

  const GradeScoreField({
    required this.controller,
    required this.fillColor,
    this.isInt = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
        inputFormatters: isInt
            ? [FilteringTextInputFormatter.digitsOnly]
            : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: fillColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
