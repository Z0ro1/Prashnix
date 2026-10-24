import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/quiz_provider.dart';

class FeedbackDrawer extends StatelessWidget {
  final QuizStatus status;
  final VoidCallback onContinue;
  final String correctOptionText;
  final String? explanation;

  const FeedbackDrawer({
    super.key,
    required this.status,
    required this.onContinue,
    required this.correctOptionText,
    this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    if (status != QuizStatus.checkedCorrect && status != QuizStatus.checkedIncorrect) {
      return const SizedBox.shrink();
    }

    final isCorrect = status == QuizStatus.checkedCorrect;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color coreColor = isCorrect ? AppColors.success : AppColors.error;
    final String title = isCorrect ? 'Awesome job!' : 'Incorrect answer';
    final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;
    
    final Color bgColor = isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight;
    final Color textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final Color mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48), // Padding for bottom safe area
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: coreColor, width: 3)),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: coreColor, size: 36)
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack, delay: 100.ms),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineMedium.copyWith(color: coreColor, fontWeight: FontWeight.w900),
                ).animate().fade(duration: 300.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic, delay: 100.ms),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 16),
            Text(
              'Correct Answer:',
              style: AppTypography.labelMedium.copyWith(color: mutedTextColor),
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 4),
            Text(
              correctOptionText,
              style: AppTypography.bodyLarge.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fade(delay: 250.ms),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Explanation:',
              style: AppTypography.labelMedium.copyWith(color: mutedTextColor),
            ).animate().fade(delay: 300.ms),
            const SizedBox(height: 4),
            Text(
              explanation!,
              style: AppTypography.bodyMedium.copyWith(
                color: textColor,
              ),
            ).animate().fade(delay: 350.ms),
          ],
          const SizedBox(height: 32),
          CustomButton(
            text: 'CONTINUE',
            onPressed: onContinue,
            variant: isCorrect ? ButtonVariant.success : ButtonVariant.error,
          ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack, delay: 400.ms),
        ],
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
  }
}
