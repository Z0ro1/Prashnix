import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/mistake_item_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/models/question_model.dart';
import '../../../skill_tree/presentation/theme/prashnix_colors.dart';
import '../providers/mistake_provider.dart';
import '../providers/saved_questions_provider.dart';
import '../screens/retry_sprint_screen.dart';

class MistakeCard extends ConsumerWidget {
  final MistakeItemModel item;

  const MistakeCard({super.key, required this.item});

  void _confirmRemove(BuildContext context, WidgetRef ref, String questionId) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove from Mistakes?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This question will be removed from your mistake bank. You can still practice it in normal lessons.',
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await ref.read(mistakeProvider.notifier).removeMistake(questionId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: const Color(0xFF1F2937),
                    duration: const Duration(seconds: 2),
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: PrashnixColors.green, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Question removed from mistakes',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('REMOVE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final question = item.question;
    final mistake = item.mistake;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final savedQuestionsAsync = ref.watch(savedQuestionsProvider);
    final isSaved = savedQuestionsAsync.value?.any((q) => q.id == question.id) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Formatted Subject Tag + 6-Digit ID + Bookmark + Failed Count + Delete
                  Row(
                    children: [
                      // Formatted Subject Tag (Constrained to never overflow)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: PrashnixColors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: PrashnixColors.green.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            question.formattedSubject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? PrashnixColors.greenLight : PrashnixColors.greenDarkBevel,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 1-Tap Copy 6-Digit Question ID
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Clipboard.setData(ClipboardData(text: question.displayCode));
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                              content: Text('ID #${question.displayCode} copied to clipboard!'),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : Colors.black.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '#${question.displayCode}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 11,
                                color: isDark ? Colors.white54 : Colors.black45,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),
                      const Spacer(),

                      // Failed Count Badge (if > 1)
                      if (mistake.mistakeCount > 1) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.repeat_rounded, size: 11, color: AppColors.error),
                              const SizedBox(width: 3),
                              Text(
                                '${mistake.mistakeCount}x',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Bookmark Save Button
                      IconButton(
                        tooltip: isSaved ? 'Remove bookmark' : 'Save question',
                        icon: Icon(
                          isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                          color: isSaved ? PrashnixColors.yellow : (isDark ? Colors.white38 : Colors.black38),
                          size: 22,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                        onPressed: () async {
                          if (question.id == null) return;
                          HapticFeedback.mediumImpact();
                          final nowSaved = await ref
                              .read(savedQuestionsProvider.notifier)
                              .toggleSaveStatus(question.id!);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: nowSaved
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFF374151),
                                duration: const Duration(seconds: 2),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                content: Row(
                                  children: [
                                    Icon(
                                      nowSaved
                                          ? Icons.bookmark_added_rounded
                                          : Icons.bookmark_remove_rounded,
                                      color: nowSaved
                                          ? PrashnixColors.yellow
                                          : Colors.white70,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      nowSaved
                                          ? 'Question saved to bookmarks!'
                                          : 'Question removed from bookmarks',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),

                      // Remove from Mistakes Icon Button
                      if (question.id != null) ...[
                        const SizedBox(width: 2),
                        IconButton(
                          tooltip: 'Remove from mistakes',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: isDark ? Colors.white38 : Colors.black38,
                            size: 20,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () => _confirmRemove(context, ref, question.id!),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Question Text
                  Text(
                    question.questionText,
                    style: AppTextStyles.h3.copyWith(
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User's Wrong Answer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your answer',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getOptionText(mistake.userAnswer, question),
                                style: AppTextStyles.body.copyWith(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Correct Answer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: PrashnixColors.green.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PrashnixColors.green.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: PrashnixColors.green.withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.check, color: PrashnixColors.greenDarkBevel, size: 14),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Correct answer',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? PrashnixColors.greenLight : PrashnixColors.greenDarkBevel,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getOptionText(question.correctOption, question),
                                style: AppTextStyles.body.copyWith(
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Explanation Callout Box
            if (question.explanation != null && question.explanation!.trim().isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline_rounded,
                            size: 16, color: PrashnixColors.orange),
                        const SizedBox(width: 6),
                        Text(
                          'स्पष्टीकरण (Explanation)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      question.explanation!.trim(),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Row: "Practice this question" + "Remove" button
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RetrySprintScreen(initialQuestions: [question]),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                        decoration: BoxDecoration(
                          color: PrashnixColors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: PrashnixColors.green.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.play_circle_outline_rounded,
                                size: 16, color: PrashnixColors.greenDarkBevel),
                            const SizedBox(width: 8),
                            Text(
                              'Practice question',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? PrashnixColors.greenLight : PrashnixColors.greenDarkBevel,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: PrashnixColors.greenDarkBevel),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (question.id != null) ...[
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _confirmRemove(context, ref, question.id!),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.error),
                            SizedBox(width: 4),
                            Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
    return label;
  }
}
