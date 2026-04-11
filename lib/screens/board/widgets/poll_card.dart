import 'package:flutter/material.dart';
import 'package:hansol_high_school/l10n/app_localizations.dart';
import 'package:hansol_high_school/styles/app_colors.dart';

class PollCard extends StatelessWidget {
  final List<String> options;
  final Map<String, dynamic> voters;
  final int? myVote;
  final void Function(int) onVote;

  const PollCard({
    super.key,
    required this.options,
    required this.voters,
    required this.myVote,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final l10n = AppLocalizations.of(context)!;
    final totalVotes = voters.length;
    final hasVoted = myVote != null;

    final voteCounts = List.filled(options.length, 0);
    for (var v in voters.values) {
      final idx = v as int;
      if (idx >= 0 && idx < options.length) voteCounts[idx]++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252830) : const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.theme.secondaryColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll, size: 18, color: AppColors.theme.secondaryColor),
              const SizedBox(width: 6),
              Text(l10n.poll_cardTitle, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.theme.secondaryColor)),
              const Spacer(),
              Text(l10n.poll_cardParticipants(totalVotes), style: TextStyle(
                fontSize: 12, color: AppColors.theme.darkGreyColor)),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(options.length, (i) {
            final count = voteCounts[i];
            final ratio = totalVotes > 0 ? count / totalVotes : 0.0;
            final isMyChoice = myVote == i;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: hasVoted ? null : () => onVote(i),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMyChoice
                          ? AppColors.theme.secondaryColor
                          : (isDark ? const Color(0xFF3A3D45) : const Color(0xFFE0E0E0)),
                      width: isMyChoice ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (hasVoted)
                        FractionallySizedBox(
                          widthFactor: ratio,
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isMyChoice
                                  ? AppColors.theme.secondaryColor.withAlpha(30)
                                  : AppColors.theme.darkGreyColor.withAlpha(15),
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            if (!hasVoted)
                              Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.theme.darkGreyColor),
                                ),
                              )
                            else if (isMyChoice)
                              Container(
                                width: 18, height: 18,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.theme.secondaryColor,
                                ),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            Expanded(
                              child: Text(options[i], style: TextStyle(
                                fontSize: 14,
                                fontWeight: isMyChoice ? FontWeight.w600 : FontWeight.w400,
                                color: textColor,
                              )),
                            ),
                            if (hasVoted)
                              Text('${(ratio * 100).round()}%', style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isMyChoice ? AppColors.theme.secondaryColor : AppColors.theme.darkGreyColor,
                              )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
