import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';
import 'package:hansol_high_school/styles/responsive.dart';

class CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool commentAnonymous;
  final String? replyToName;
  final VoidCallback onToggleAnonymous;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;

  const CommentInputBar({
    super.key,
    required this.controller,
    required this.sending,
    required this.commentAnonymous,
    required this.replyToName,
    required this.onToggleAnonymous,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final l = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2028) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF2A2D35) : const Color(0xFFE5E5EA))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyToName != null)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
              child: Row(
                children: [
                  Icon(Icons.reply, size: Responsive.r(context, 14), color: AppColors.theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(l.post_replyTo(replyToName!),
                    style: TextStyle(fontSize: Responsive.sp(context, 12), color: AppColors.theme.primaryColor)),
                  const Spacer(),
                  Semantics(
                    button: true,
                    label: 'Cancel reply',
                    child: GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(Icons.close, size: Responsive.r(context, 16), color: AppColors.theme.darkGreyColor),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Semantics(
                button: true,
                label: l.post_anonymous,
                child: GestureDetector(
                onTap: onToggleAnonymous,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: commentAnonymous
                        ? AppColors.theme.primaryColor.withAlpha(20)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: commentAnonymous
                          ? AppColors.theme.primaryColor
                          : AppColors.theme.darkGreyColor,
                    ),
                  ),
                  child: Text(l.post_anonymous,
                    style: TextStyle(
                      fontSize: Responsive.sp(context, 12), fontWeight: FontWeight.w600,
                      color: commentAnonymous
                          ? AppColors.theme.primaryColor
                          : AppColors.theme.darkGreyColor,
                    ),
                  ),
                ),
              )),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(fontSize: Responsive.sp(context, 14), color: textColor),
                  decoration: InputDecoration(
                    hintText: replyToName != null ? '@$replyToName' : l.post_commentPlaceholder,
                    hintStyle: TextStyle(color: AppColors.theme.darkGreyColor),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF252830) : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: sending ? null : onSubmit,
                tooltip: 'Send comment',
                icon: Icon(Icons.send, color: AppColors.theme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
