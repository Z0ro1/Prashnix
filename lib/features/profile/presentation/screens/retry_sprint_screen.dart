import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/state/user_state.dart';
import '../../../quiz/presentation/widgets/feedback_drawer.dart';
import '../../../quiz/presentation/widgets/interactive_option_pill.dart';
import '../../../quiz/presentation/widgets/quiz_progress_bar.dart';
import '../../../quiz/presentation/providers/quiz_provider.dart'; // For QuizStatus
import '../../../skill_tree/presentation/theme/prashnix_colors.dart';
import '../providers/retry_sprint_provider.dart';

class RetrySprintScreen extends ConsumerWidget {
  final List<QuestionModel> initialQuestions;

  const RetrySprintScreen({super.key, required this.initialQuestions});

  void _showExitDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final parentNav = Navigator.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1D24) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: AppColors.error.withValues(alpha: 0.3), width: 1.5),
          ),
          title: Text(
            'Quit Retry Session?',
            style: AppTextStyles.h2.copyWith(color: isDark ? Colors.white : AppColors.textPrimary),
          ),
          content: Text(
            "Your mistakes will remain uncleared. Are you sure you want to exit?",
            style: AppTextStyles.body.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CANCEL',
                style: AppTextStyles.label.copyWith(color: isDark ? Colors.white54 : AppColors.textMuted),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  parentNav.pop();
                },
                child: Text(
                  'QUIT',
                  style: AppTextStyles.label.copyWith(color: AppColors.error, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(retrySprintProvider(initialQuestions));
    final notifier = ref.read(retrySprintProvider(initialQuestions).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F1115) : AppColors.backgroundLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final closeIconColor = isDark ? Colors.white54 : AppColors.textSecondary;
    final footerColor = isDark ? const Color(0xFF1A1D24) : Colors.white;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == RetryStatus.finished) {
        final earnedXp = state.clearedCount * 2;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Awesome! You cleared ${state.clearedCount} mistakes! (+$earnedXp XP)',
              style: AppTextStyles.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: PrashnixColors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.of(context).pop();
      }
    });

    final question = state.currentQuestion;
    if (question == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator(color: PrashnixColors.green)),
      );
    }

    // Map RetryStatus to QuizStatus for FeedbackDrawer
    QuizStatus mappedStatus = QuizStatus.unanswered;
    if (state.status == RetryStatus.checkedCorrect) mappedStatus = QuizStatus.checkedCorrect;
    if (state.status == RetryStatus.checkedIncorrect) mappedStatus = QuizStatus.checkedIncorrect;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: closeIconColor),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: PrashnixColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: PrashnixColors.red.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.favorite, color: PrashnixColors.red, size: 16)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1.seconds),
                        const SizedBox(width: 6),
                        Text(
                          ref.watch(userStoreProvider).heartCount.toString(),
                          style: AppTextStyles.h3.copyWith(color: PrashnixColors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Question Content Body
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
                          color: PrashnixColors.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: PrashnixColors.green.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'Retry: ${question.formattedSubject}',
                          style: TextStyle(
                            color: isDark ? PrashnixColors.greenLight : PrashnixColors.greenDarkBevel,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ).animate().fade().slideX(begin: -0.2),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      question.questionText,
                      style: AppTextStyles.h2.copyWith(color: textColor, height: 1.4),
                    ).animate(key: ValueKey(question.id)).fade(duration: 400.ms).slideY(begin: 0.1),
                    const SizedBox(height: 36),

                    ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                      final index = entry.key;
                      final label = entry.value;

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

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: InteractiveOptionPill(
                          label: label,
                          text: text,
                          state: pillState,
                          onTap: () {
                            if (state.status == RetryStatus.unanswered || state.status == RetryStatus.selected) {
                              notifier.selectOption(label);
                            }
                          },
                        ).animate(key: ValueKey('${question.id}_$label')).fade(delay: (100 + (index * 100)).ms).slideX(begin: 0.1),
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
                  color: footerColor,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: state.status == RetryStatus.selected ? () => notifier.checkAnswer() : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PrashnixColors.green,
                      disabledBackgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.06),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: state.status == RetryStatus.selected ? 6 : 0,
                      shadowColor: PrashnixColors.greenDarkBevel.withValues(alpha: 0.4),
                    ),
                    child: Text(
                      'CHECK',
                      style: TextStyle(
                        color: state.status == RetryStatus.selected
                            ? Colors.white
                            : (isDark ? Colors.white24 : Colors.black26),
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ).animate().slideY(begin: 1, duration: 300.ms, curve: Curves.easeOutBack),
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
