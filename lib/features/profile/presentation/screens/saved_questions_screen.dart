import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/models/question_model.dart';
import '../providers/saved_questions_provider.dart';

class SavedQuestionsScreen extends ConsumerWidget {
  const SavedQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedQuestionsAsync = ref.watch(savedQuestionsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Saved Questions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: savedQuestionsAsync.when(
        data: (questions) {
          if (questions.isEmpty) {
            return _buildEmptyState(textColor);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final question = questions[index];
              return _buildQuestionCard(context, ref, question, textColor, isDark);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryMint)),
        error: (error, stack) => Center(
          child: Text('Error loading saved questions: $error', style: TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_rounded, size: 80, color: textColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No saved questions yet.',
            style: AppTextStyles.h3.copyWith(color: textColor.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon during a quiz\nto save questions here.',
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: textColor.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, WidgetRef ref, QuestionModel question, Color textColor, bool isDark) {
    final cardColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: isDark ? 0.1 : 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.questionText,
                  style: AppTextStyles.h3.copyWith(color: textColor),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.bookmark_rounded, color: AppColors.skyBlue),
                onPressed: () {
                  if (question.id != null) {
                    ref.read(savedQuestionsProvider.notifier).toggleSaveStatus(question.id!);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildOptionRow('A', question.optionA, question.correctOption == 'A', textColor),
          _buildOptionRow('B', question.optionB, question.correctOption == 'B', textColor),
          _buildOptionRow('C', question.optionC, question.correctOption == 'C', textColor),
          _buildOptionRow('D', question.optionD, question.correctOption == 'D', textColor),
          
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.featherGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.featherGreen.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.featherGreen, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: AppTextStyles.body.copyWith(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, String text, bool isCorrect, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label.',
            style: AppTextStyles.body.copyWith(
              color: isCorrect ? AppColors.featherGreen : textColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.body.copyWith(
                color: isCorrect ? AppColors.featherGreen : textColor.withValues(alpha: 0.8),
                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (isCorrect)
            const Icon(Icons.check_circle_rounded, color: AppColors.featherGreen, size: 20),
        ],
      ),
    );
  }
}
