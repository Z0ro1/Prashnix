import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
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
    
    final Color bgColor = isCorrect ? const Color(0xFFE6F9F3) : const Color(0xFFFFEAEA);
    final Color textColor = isCorrect ? AppColors.success : AppColors.error;
    final String title = isCorrect ? 'Awesome job!' : 'Incorrect answer';
    final IconData icon = isCorrect ? Icons.check_circle : Icons.cancel;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), // Padding for bottom safe area
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.h2.copyWith(color: textColor),
                ),
              ),
            ],
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 12),
            Text(
              'Correct Answer:',
              style: AppTextStyles.label.copyWith(color: textColor),
            ),
            Text(
              correctOptionText,
              style: AppTextStyles.body.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Explanation:',
              style: AppTextStyles.label.copyWith(color: textColor),
            ),
            Text(
              explanation!,
              style: AppTextStyles.body.copyWith(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 24),
          CustomButton(
            text: 'CONTINUE',
            onPressed: onContinue,
            backgroundColor: textColor,
            shadowColor: isCorrect ? const Color(0xFF46A035) : const Color(0xFFC73624), // approximate darker shades
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }
}
