import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
import '../../../quiz/presentation/widgets/feedback_drawer.dart';
import '../../../quiz/presentation/widgets/interactive_option_pill.dart';
import '../../../quiz/presentation/widgets/quiz_progress_bar.dart';
import '../../../quiz/presentation/providers/quiz_provider.dart'; // For QuizStatus
import '../providers/retry_sprint_provider.dart';

class RetrySprintScreen extends ConsumerWidget {
  final List<QuestionModel> initialQuestions;

  const RetrySprintScreen({super.key, required this.initialQuestions});

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Retry Session?'),
        content: const Text("Your mistakes will remain uncleared."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit screen
            },
            child: const Text('QUIT', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(retrySprintNotifierProvider(initialQuestions));
    final heartState = ref.watch(heartEconomyProvider);
    final notifier = ref.read(retrySprintNotifierProvider(initialQuestions).notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == RetryStatus.finished) {
        // Show success and pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Awesome! You cleared ${state.clearedCount} mistakes! (+${state.clearedCount} ❤️)')),
        );
        Navigator.of(context).pop();
      }
    });

    final question = state.currentQuestion;
    if (question == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Map RetryStatus to QuizStatus for FeedbackDrawer
    QuizStatus mappedStatus = QuizStatus.unanswered;
    if (state.status == RetryStatus.checkedCorrect) mappedStatus = QuizStatus.checkedCorrect;
    if (state.status == RetryStatus.checkedIncorrect) mappedStatus = QuizStatus.checkedIncorrect;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => _showExitDialog(context),
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
                      const Text('❤️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        heartState.heartCount.toString(),
                        style: AppTextStyles.h3.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Retry: ${question.subjectTag}',
                          style: AppTextStyles.label.copyWith(
                            color: const Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      question.questionText,
                      style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 48),

                    ...['A', 'B', 'C', 'D'].map((label) {
                      String text;
                      if (label == 'A') text = question.optionA;
                      else if (label == 'B') text = question.optionB;
                      else if (label == 'C') text = question.optionC;
                      else text = question.optionD;

                      OptionState pillState = OptionState.defaultState;
                      
                      if (state.status == RetryStatus.selected && state.selectedOption == label) {
                        pillState = OptionState.selected;
                      } else if (state.status == RetryStatus.checkedCorrect && state.selectedOption == label) {
                        pillState = OptionState.correct;
                      } else if (state.status == RetryStatus.checkedIncorrect) {
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
                          if (state.status == RetryStatus.unanswered || state.status == RetryStatus.selected) {
                            notifier.selectOption(label);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Footer
            if (state.status == RetryStatus.checkedCorrect || state.status == RetryStatus.checkedIncorrect)
              FeedbackDrawer(
                status: mappedStatus,
                correctOptionText: _getCorrectOptionText(question),
                onContinue: () => notifier.nextQuestion(),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.surfaceLight)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: state.status == RetryStatus.selected ? () => notifier.checkAnswer() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: state.status == RetryStatus.selected ? 4 : 0,
                    ),
                    child: Text(
                      'CHECK',
                      style: AppTextStyles.h3.copyWith(
                        color: state.status == RetryStatus.selected ? Colors.white : AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
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
