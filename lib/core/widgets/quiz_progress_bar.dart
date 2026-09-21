import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class QuizProgressBar extends StatelessWidget {
  final int totalSegments;
  final int currentProgress;

  const QuizProgressBar({
    super.key,
    required this.totalSegments,
    required this.currentProgress,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Spacing between segments
        final spacing = 4.0;
        final totalSpacing = spacing * (totalSegments - 1);
        final segmentWidth = (availableWidth - totalSpacing) / totalSegments;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSegments, (index) {
            final isCompleted = index < currentProgress;
            final isCurrent = index == currentProgress;

            return AnimatedContainer(
              duration: AppConstants.animationMedium,
              curve: Curves.easeInOut,
              height: 8,
              width: segmentWidth,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.primaryMint
                    : isCurrent
                        ? AppColors.accentAmber
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
                boxShadow: isCompleted || isCurrent
                    ? [
                        BoxShadow(
                          color: isCompleted
                              ? AppColors.primaryMint.withValues(alpha: 0.4)
                              : AppColors.accentAmber.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
