import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/models/mistake_item_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/models/question_model.dart';

class MistakeCard extends StatelessWidget {
  final MistakeItemModel item;

  const MistakeCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final question = item.question;
    final mistake = item.mistake;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          question.subjectTag,
                          style: AppTextStyles.label.copyWith(color: AppColors.primaryGreenDark),
                        ),
                      ),
                      if (mistake.mistakeCount > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Failed ${mistake.mistakeCount}x',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.error, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.questionText,
                    style: AppTextStyles.h3.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  ),
                  const SizedBox(height: 20),
                  
                  // User's wrong answer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.error.withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.close, color: AppColors.error, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getOptionText(mistake.userAnswer, question),
                            style: AppTextStyles.body.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // Correct answer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryGreen.withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.check, color: AppColors.primaryGreenDark, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _getOptionText(question.correctOption, question),
                            style: AppTextStyles.body.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            if (question.explanation != null && question.explanation!.isNotEmpty)
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  unselectedWidgetColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  colorScheme: const ColorScheme.light(primary: AppColors.primaryGreenDark),
                ),
                child: ExpansionTile(
                  title: Text(
                    'View Explanation',
                    style: AppTextStyles.label.copyWith(color: AppColors.primaryGreenDark, fontWeight: FontWeight.bold),
                  ),
                  iconColor: AppColors.primaryGreenDark,
                  collapsedIconColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Text(
                        question.explanation!,
                        style: AppTextStyles.body.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getOptionText(String label, QuestionModel q) {
    if (label == 'A') return q.optionA;
    if (label == 'B') return q.optionB;
    if (label == 'C') return q.optionC;
    if (label == 'D') return q.optionD;
    return 'Unknown';
  }
}
