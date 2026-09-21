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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        question.subjectTag,
                        style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    if (mistake.mistakeCount > 1)
                      Text(
                        'Failed ${mistake.mistakeCount}x',
                        style: AppTextStyles.label.copyWith(color: AppColors.error),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  question.questionText,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // User's wrong answer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.close, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getOptionText(mistake.userAnswer, question),
                          style: AppTextStyles.body.copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),

                // Correct answer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getOptionText(question.correctOption, question),
                          style: AppTextStyles.body.copyWith(color: AppColors.success),
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
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(
                  'View Explanation',
                  style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      question.explanation!,
                      style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
