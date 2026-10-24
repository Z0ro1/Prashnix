import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/state/user_state.dart';
import '../../../profile/presentation/providers/settings_provider.dart';
import '../../../gamification/presentation/widgets/heart_refill_modal_sheet.dart';
import '../providers/quiz_provider.dart';
import '../widgets/feedback_drawer.dart';
import '../widgets/interactive_option_pill.dart';
import '../widgets/quiz_progress_bar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../profile/presentation/providers/saved_questions_provider.dart';
import 'quiz_summary_screen.dart';

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  void _showExitDialog(BuildContext parentContext) {
    showDialog<bool>(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text('Quit lesson?', style: AppTypography.headlineSmall),
        content: Text("Your progress won't be saved.", style: AppTypography.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('CANCEL', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGreen)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('QUIT', style: AppTypography.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && parentContext.mounted) {
        if (Navigator.of(parentContext).canPop()) {
          Navigator.of(parentContext).pop();
        } else {
          parentContext.go('/home');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quizProvider);
    final userState = ref.watch(userStoreProvider);
    final notifier = ref.read(quizProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    // Redirect if finished or out of hearts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == QuizStatus.finished) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuizSummaryScreen()),
        );
      } else if (state.status == QuizStatus.outOfHearts) {
        HeartRefillModalSheet.show(context);
        // And probably exit quiz or pause
      }
    });

    final question = state.currentQuestion;
    
    final savedQuestionsState = ref.watch(savedQuestionsProvider);
    final savedQuestions = savedQuestionsState.value ?? [];
    final isSaved = question != null && savedQuestions.any((q) => q.id == question.id);

    if (state.isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: AppColors.primaryGreen,
                  strokeWidth: 4,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scaleXY(begin: 0.95, end: 1.05, duration: 1.seconds, curve: Curves.easeInOut),
              const SizedBox(height: 24),
              Text(
                "Syncing latest questions...",
                style: AppTypography.labelLarge.copyWith(color: mutedColor),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .fade(begin: 0.5, end: 1.0, duration: 800.ms),
            ],
          ),
        ),
      );
    }

    if (question == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'No questions available for this lesson.',
                style: AppTypography.headlineSmall.copyWith(color: textColor),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: Text('Go Back', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor, 
      body: SafeArea(
        child: Column(
          children: [
            // Header Navigation Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: mutedColor),
                    onPressed: () {
                      if (ref.read(settingsProvider).hapticsEnabled) {
                        HapticFeedback.lightImpact();
                      }
                      _showExitDialog(context);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: QuizProgressBar(
                      currentIndex: state.currentIndex,
                      totalQuestions: state.questions.length,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      if (question.id != null)
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isSaved ? AppColors.waterBlue : mutedColor,
                          ),
                          onPressed: () {
                            if (ref.read(settingsProvider).hapticsEnabled) {
                              HapticFeedback.lightImpact();
                            }
                            ref.read(savedQuestionsProvider.notifier).toggleSaveStatus(question.id!);
                          },
                        ),
                      const SizedBox(width: 4),
                      const Text('❤️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        userState.heartCount.toString(),
                        style: AppTypography.headlineSmall.copyWith(color: AppColors.error),
                      ).animate(target: state.status == QuizStatus.checkedIncorrect ? 1 : 0)
                       .shakeX(duration: 400.ms, hz: 6)
                       .tint(color: Colors.white, duration: 200.ms),
                    ],
                  ),
                ],
              ),
            ),

            // Question Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Subject Tag
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          question.subjectTag,
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryGreenDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Question Text
                    Text(
                      question.questionText,
                      style: AppTypography.headlineMedium.copyWith(color: textColor, height: 1.4),
                    ).animate(key: ValueKey(question.id)).fade(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Q-ID: ${question.id}',
                          style: AppTypography.labelSmall.copyWith(
                            color: mutedColor,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Options
                    ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                      final int index = entry.key;
                      final String label = entry.value;

                      String text;
                      if (label == 'A') {
                        text = question.optionA;
                      } else if (label == 'B') {
                        text = question.optionB;
                      } else if (label == 'C') {
                        text = question.optionC;
                      } else {
                        text = question.optionD;
                      }

                      OptionState pillState = OptionState.defaultState;
                      
                      if (state.status == QuizStatus.selected && state.selectedOption == label) {
                        pillState = OptionState.selected;
                      } else if (state.status == QuizStatus.checkedCorrect && state.selectedOption == label) {
                        pillState = OptionState.correct;
                      } else if (state.status == QuizStatus.checkedIncorrect) {
                        if (state.selectedOption == label) {
                          pillState = OptionState.incorrect;
                        } else if (question.correctOption == label) {
                          pillState = OptionState.correct;
                        }
                      }

                      return InteractiveOptionPill(
                        label: label,
                        text: text,
                        state: pillState,
                        onTap: () {
                          if (state.status == QuizStatus.unanswered || state.status == QuizStatus.selected) {
                            notifier.selectOption(label);
                          }
                        },
                      ).animate(key: ValueKey('${question.id}_$label'))
                       .fade(delay: (200 + (index * 100)).ms, duration: 400.ms)
                       .slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack, delay: (200 + (index * 100)).ms);
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Actions & Feedback Drawer
            if (state.status == QuizStatus.checkedCorrect || state.status == QuizStatus.checkedIncorrect)
              FeedbackDrawer(
                status: state.status,
                correctOptionText: _getCorrectOptionText(question),
                explanation: question.explanation,
                onContinue: () => notifier.nextQuestion(),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                child: CustomButton(
                  text: 'CHECK',
                  variant: state.status == QuizStatus.selected ? ButtonVariant.primaryGreen : ButtonVariant.disabled,
                  onPressed: state.status == QuizStatus.selected ? () => notifier.checkAnswer() : null,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getCorrectOptionText(QuestionModel q) {
    if (q.correctOption == 'A') return q.optionA;
    if (q.correctOption == 'B') return q.optionB;
    if (q.correctOption == 'C') return q.optionC;
    return q.optionD;
  }
}
