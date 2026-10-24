import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../providers/quiz_provider.dart';

class QuizSummaryScreen extends ConsumerWidget {
  const QuizSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizProvider);
    final int correct = state.correctAnswers;
    final int total = state.questions.length;
    final double progress = total > 0 ? (correct / total) : 0.0;
    final int accuracy = (progress * 100).round();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedTextColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Sprint Complete!',
                style: AppTypography.displayHero.copyWith(
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ).animate().fade().slideY(begin: -0.2),
              const SizedBox(height: 48),
              
              // Accuracy Ring / Score using the new ProgressRing
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: 1500.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ProgressRing(
                      progress: value,
                      size: 220,
                      strokeWidth: 20,
                      activeColor: AppColors.primaryGreenDark,
                      inactiveColor: AppColors.primaryGreen,
                      centerContent: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$accuracy%',
                            style: AppTypography.displayHero.copyWith(
                              color: AppColors.primaryGreenDark,
                            ),
                          ),
                          Text(
                            '$correct / $total Correct',
                            style: AppTypography.labelLarge.copyWith(color: mutedTextColor),
                          ),
                        ],
                      ),
                    );
                  },
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
              ),
              
              const SizedBox(height: 48),
              
              // Rewards Breakdown using the clean AppCard
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total XP Earned', style: AppTypography.headlineSmall.copyWith(color: textColor)),
                        Text('+${state.baseXpEarned} XP', style: AppTypography.headlineMedium.copyWith(color: AppColors.primaryGreenDark)),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Streak Increase', style: AppTypography.headlineSmall.copyWith(color: textColor)),
                        Text('+${state.streakIncrement} 🔥', style: AppTypography.headlineMedium.copyWith(color: AppColors.stepOrange)),
                      ],
                    ),
                  ],
                ),
              ).animate().fade(delay: 800.ms).slideY(begin: 0.2),
              
              const Spacer(),
              
              if (correct < total) ...[
                CustomButton(
                  text: 'Review Mistakes',
                  variant: ButtonVariant.outline,
                  onPressed: () {
                    // Navigate to Phase 8 Mistake Review
                  },
                ).animate().fade(delay: 1000.ms),
                const SizedBox(height: 16),
              ],
              
              CustomButton(
                text: 'Continue to Roadmap ➔',
                variant: ButtonVariant.primaryMint,
                onPressed: () {
                  Navigator.of(context).pop(); // Should pop back to roadmap
                },
              ).animate().fade(delay: 1200.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
