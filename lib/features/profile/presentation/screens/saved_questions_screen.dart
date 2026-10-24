import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/models/question_model.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../providers/saved_questions_provider.dart';

class SavedQuestionsScreen extends ConsumerWidget {
  const SavedQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedQuestionsAsync = ref.watch(savedQuestionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        title: Text('Saved Questions', style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: 50,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
              height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.canaryYellow.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await SyncService().pullProgress();
                ref.invalidate(savedQuestionsProvider);
                await ref.read(savedQuestionsProvider.future);
              },
              color: AppColors.canaryYellow,
              backgroundColor: const Color(0xFF1A1D24),
              displacement: 40,
              child: savedQuestionsAsync.when(
                skipLoadingOnReload: true,
                data: (questions) {
                  if (questions.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    itemCount: questions.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return _buildQuestionCard(context, ref, question)
                          .animate()
                          .fade(delay: (100 * index).ms)
                          .slideY(begin: 0.1, curve: Curves.easeOutCubic);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.canaryYellow)),
                error: (error, stack) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: Text('Error: $error', style: AppTextStyles.body.copyWith(color: AppColors.error)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Container(
        height: 500,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.canaryYellow.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(color: AppColors.canaryYellow.withValues(alpha: 0.2), blurRadius: 40)
                ]
              ),
              child: const Icon(Icons.bookmark_border_rounded, size: 80, color: AppColors.canaryYellow),
            ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
            const SizedBox(height: 32),
            Text(
              'No saved questions yet.',
              style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 12),
            Text(
              'Tap the bookmark icon during a quiz\nto save questions here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.white54, height: 1.5),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            Text(
              'Pull down to reload',
              style: AppTextStyles.caption.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(BuildContext context, WidgetRef ref, QuestionModel question) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                      style: AppTextStyles.h3.copyWith(color: Colors.white, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      if (question.id != null) {
                        ref.read(savedQuestionsProvider.notifier).toggleSaveStatus(question.id!);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.canaryYellow.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.canaryYellow.withValues(alpha: 0.3)),
                      ),
                      child: const Icon(Icons.bookmark_rounded, color: AppColors.canaryYellow, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Options
              _buildOptionRow('A', question.optionA, question.correctOption == 'A'),
              _buildOptionRow('B', question.optionB, question.correctOption == 'B'),
              _buildOptionRow('C', question.optionC, question.correctOption == 'C'),
              _buildOptionRow('D', question.optionD, question.correctOption == 'D'),
              
              if (question.explanation != null && question.explanation!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryMint.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryMint, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.explanation!,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(String label, String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isCorrect ? AppColors.primaryMint.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCorrect ? AppColors.primaryMint.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label.',
              style: AppTextStyles.h3.copyWith(
                color: isCorrect ? AppColors.primaryMint : Colors.white30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.body.copyWith(
                  color: isCorrect ? Colors.white : Colors.white70,
                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryMint, size: 20),
          ],
        ),
      ),
    );
  }
}
