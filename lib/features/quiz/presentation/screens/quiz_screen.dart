import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/state/user_state.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
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

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit lesson?'),
        content: const Text("Your progress won't be saved."),
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
    final state = ref.watch(quizProvider);
    final heartState = ref.watch(heartEconomyProvider);
    final userState = ref.watch(userStoreProvider);
    final notifier = ref.read(quizProvider.notifier);

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
    final isSaved = savedQuestionsState.when(
      data: (savedQuestions) => question != null && savedQuestions.any((q) => q.id == question.id),
      loading: () => false,
      error: (_, __) => false,
    );

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (question == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'No questions available for this lesson.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Navigation Bar
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
                      if (question.id != null)
                        IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isSaved ? AppColors.skyBlue : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            ref.read(savedQuestionsProvider.notifier).toggleSaveStatus(question.id!);
                          },
                        ),
                      const SizedBox(width: 4),
                      const Text('❤️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        userState.heartCount.toString(),
                        style: AppTextStyles.h3.copyWith(color: AppColors.error),
                      ),
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
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.subjectTag,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Question Text
                    Text(
                      question.questionText,
                      style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary, height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3), width: 0.5),
                        ),
                        child: Text(
                          'Q-ID: ${question.id}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Options
                    ...['A', 'B', 'C', 'D'].map((label) {
                      String text;
                      if (label == 'A') text = question.optionA;
                      else if (label == 'B') text = question.optionB;
                      else if (label == 'C') text = question.optionC;
                      else text = question.optionD;

                      OptionState pillState = OptionState.defaultState;
                      
                      if (state.status == QuizStatus.selected && state.selectedOption == label) {
                        pillState = OptionState.selected;
                      } else if (state.status == QuizStatus.checkedCorrect && state.selectedOption == label) {
                        pillState = OptionState.correct;
                      } else if (state.status == QuizStatus.checkedIncorrect) {
                        if (state.selectedOption == label) {
                          pillState = OptionState.incorrect;
                        } else if (question.correctOption == label) {
                          // Optionally highlight the correct one
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
                      );
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
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(top: BorderSide(color: AppColors.surfaceLight)),
                ),
                child: CustomButton(
                  text: 'CHECK',
                  variant: state.status == QuizStatus.selected ? ButtonVariant.primaryMint : ButtonVariant.disabled,
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
