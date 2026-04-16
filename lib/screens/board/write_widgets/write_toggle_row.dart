import 'package:flutter/material.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class WriteToggleRow extends StatelessWidget {
  final bool value;
  final VoidCallback onTap;
  final String label;
  final Color activeColor;
  final IconData? icon;
  final Color? iconColor;
  final FontWeight labelWeight;

  const WriteToggleRow({
    super.key,
    required this.value,
    required this.onTap,
    required this.label,
    required this.activeColor,
    this.icon,
    this.iconColor,
    this.labelWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = value ? activeColor : AppColors.theme.darkGreyColor;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: value ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: value
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(
            fontSize: 14,
            fontWeight: labelWeight,
            color: textColor,
          )),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: iconColor ?? activeColor),
          ],
        ],
      ),
    );
  }
}
