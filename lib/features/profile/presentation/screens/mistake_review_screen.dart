import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/mistake_provider.dart';
import '../widgets/mistake_card.dart';
import 'retry_sprint_screen.dart';

class MistakeReviewScreen extends ConsumerWidget {
  const MistakeReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mistakeNotifierProvider);
    final notifier = ref.read(mistakeNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mistake Bank', style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
            if (!state.isLoading)
              Text(
                '${state.mistakes.length} Mistakes Remaining',
                style: AppTextStyles.label.copyWith(color: AppColors.error),
              ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter Chips
                if (state.mistakes.isNotEmpty)
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.availableFilters.length,
                      itemBuilder: (context, index) {
                        final filter = state.availableFilters[index];
                        final isActive = filter == state.activeFilter;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isActive,
                            selectedColor: AppColors.primary.withValues(alpha: 0.1),
                            backgroundColor: AppColors.surfaceLighter,
                            labelStyle: TextStyle(
                              color: isActive ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isActive ? AppColors.primary : AppColors.surfaceLight,
                            ),
                            onSelected: (selected) {
                              if (selected) notifier.setFilter(filter);
                            },
                          ),
                        );
                      },
                    ),
                  ),

                // List
                Expanded(
                  child: state.filteredMistakes.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics: const BouncingScrollPhysics(),
                          itemCount: state.filteredMistakes.length,
                          itemBuilder: (context, index) {
                            return MistakeCard(item: state.filteredMistakes[index]);
                          },
                        ),
                ),

                // Retry Session Footer
                if (state.mistakes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        )
                      ],
                    ),
                    child: CustomButton(
                      text: 'Clear Mistakes Now (+1 ❤️ Bonus)',
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        // Launch Retry Sprint
                        final questions = state.mistakes.map((m) => m.question).toList();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RetrySprintScreen(initialQuestions: questions),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            'No mistakes found!',
            style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up. Keep learning!",
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
