import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/state/user_state.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../providers/mistake_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mistake_card.dart';
import 'retry_sprint_screen.dart';

class MistakeReviewScreen extends ConsumerWidget {
  const MistakeReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mistakeProvider);
    final notifier = ref.read(mistakeProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.heart_broken_rounded, color: AppColors.error, size: 24)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds),
            ).animate().fade().scale(curve: Curves.easeOutBack),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mistake Bank',
                  style: AppTextStyles.h2.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ).animate().fade(delay: 100.ms).slideX(begin: -0.1),
                if (!state.isLoading)
                  Text(
                    '${state.mistakes.length} mistakes to clear',
                    style: AppTextStyles.label.copyWith(color: AppColors.error),
                  ).animate().fade(delay: 200.ms).slideX(begin: -0.1),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (ref.read(settingsProvider).hapticsEnabled) {
              HapticFeedback.mediumImpact();
            }
            await Future.wait([
              ref.read(userStoreProvider.notifier).refreshProfile(),
              SyncService().pullProgress(),
            ]);
            await notifier.loadMistakes();
          },
          color: AppColors.primaryGreenDark,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          displacement: 40,
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreenDark))
              : Column(
                  children: [
                    // Filter Chips
                    if (state.mistakes.isNotEmpty)
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                        ),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: state.availableFilters.length,
                          itemBuilder: (context, index) {
                            final filter = state.availableFilters[index];
                            final isActive = filter == state.activeFilter;

                            return GestureDetector(
                              onTap: () {
                                if (ref.read(settingsProvider).hapticsEnabled) {
                                  HapticFeedback.lightImpact();
                                }
                                notifier.setFilter(filter);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight) : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight) : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                ),
                                child: Text(
                                  filter,
                                  style: AppTextStyles.label.copyWith(
                                    color: isActive ? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight) : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ).animate().fade(delay: (200 + (index * 50)).ms).slideX();
                          },
                        ),
                      ),

                    // List or Empty State
                    Expanded(
                      child: state.filteredMistakes.isEmpty
                          ? _buildEmptyState(context)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 160), // padding for FAB + Nav bar
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              itemCount: state.filteredMistakes.length,
                              itemBuilder: (context, index) {
                                return MistakeCard(item: state.filteredMistakes[index])
                                    .animate()
                                    .fade(delay: (100 + (index * 100)).ms)
                                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
      
      // Floating Retry Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: state.mistakes.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 90), // push above nav bar
              child: GestureDetector(
                  onTap: () {
                    if (ref.read(settingsProvider).hapticsEnabled) {
                      HapticFeedback.mediumImpact();
                    }
                    final questions = state.mistakes.map((m) => m.question).toList();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RetrySprintScreen(initialQuestions: questions),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white : AppColors.textPrimaryLight, // Modern contrast button
                      borderRadius: BorderRadius.circular(30),
                  boxShadow: AppColors.softCardShadow,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Clear Mistakes (+1 ❤️)',
                      style: AppTextStyles.h3.copyWith(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds)
            ).animate().fade(delay: 400.ms).slideY(begin: 1, end: 0, curve: Curves.easeOutBack)
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.65,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.primaryGreenDark, size: 64),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
            const SizedBox(height: 24),
            Text(
              'Flawless!',
              style: AppTextStyles.h1.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ).animate().fade(delay: 200.ms).slideY(),
            const SizedBox(height: 8),
            Text(
              "You have zero pending mistakes.\nKeep up the perfect streak!",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, height: 1.5),
            ).animate().fade(delay: 300.ms).slideY(),
            const SizedBox(height: 16),
            Text(
              "Pull down to refresh",
              style: AppTextStyles.caption.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ],
        ),
      ),
    );
  }
}
