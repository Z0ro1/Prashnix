import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/quiz_provider.dart';

class QuizSummaryScreen extends ConsumerWidget {
  const QuizSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizProvider);
    final int correct = state.correctAnswers;
    final int total = state.questions.length;
    final int accuracy = total > 0 ? ((correct / total) * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Sprint Complete!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Accuracy Ring / Score
              Center(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$accuracy%',
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          '$correct / $total Correct',
                          style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Rewards Breakdown
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLighter,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceLight),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total XP Earned', style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                        Text('+${state.baseXpEarned} XP', style: AppTextStyles.h3.copyWith(color: const Color(0xFF00BFFF))),
                      ],
                    ),
                    const Divider(height: 32, color: AppColors.surfaceLight),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Streak Increase', style: AppTextStyles.body.copyWith(color: AppColors.textPrimary)),
                        Text('+${state.streakIncrement} 🔥', style: AppTextStyles.h3.copyWith(color: const Color(0xFFFF9800))),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              if (correct < total) ...[
                CustomButton(
                  text: 'Review Mistakes',
                  variant: ButtonVariant.outline,
                  onPressed: () {
                    // Navigate to Phase 8 Mistake Review
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              CustomButton(
                text: 'Continue to Roadmap ➔',
                variant: ButtonVariant.primaryMint,
                onPressed: () {
                  Navigator.of(context).pop(); // Should pop back to roadmap
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
