import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/models/mistake_item_model.dart';
import '../../../../core/models/question_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/state/user_state.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../../../skill_tree/presentation/theme/prashnix_colors.dart';
import '../providers/mistake_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/mistake_card.dart';
import 'retry_sprint_screen.dart';

class MistakeReviewScreen extends ConsumerWidget {
  const MistakeReviewScreen({super.key});

  void _startSprint(BuildContext context, WidgetRef ref, {List<QuestionModel>? customQuestions, int count = 5}) {
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.mediumImpact();
    }
    final state = ref.read(mistakeProvider);
    final pool = customQuestions ?? state.filteredMistakes.map((m) => m.question).toList();
    if (pool.isEmpty) return;

    // Prioritize questions with highest mistake counts so most failed questions come first
    final sortedPool = List<MistakeItemModel>.from(state.filteredMistakes)
      ..sort((a, b) => b.mistake.mistakeCount.compareTo(a.mistake.mistakeCount));

    final rawQuestions = customQuestions ?? sortedPool.map((m) => m.question).toList();
    final uniqueSprintQuestions = <QuestionModel>[];
    final seenIds = <String>{};
    final seenTexts = <String>{};

    for (final q in rawQuestions) {
      final idKey = q.id ?? '';
      final textKey = q.questionText.trim().toLowerCase();

      if (idKey.isNotEmpty && seenIds.contains(idKey)) continue;
      if (textKey.isNotEmpty && seenTexts.contains(textKey)) continue;

      if (idKey.isNotEmpty) seenIds.add(idKey);
      if (textKey.isNotEmpty) seenTexts.add(textKey);
      uniqueSprintQuestions.add(q);

      if (uniqueSprintQuestions.length >= count) break;
    }

    if (uniqueSprintQuestions.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RetrySprintScreen(initialQuestions: uniqueSprintQuestions),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mistakeProvider);
    final notifier = ref.read(mistakeProvider.notifier);
    final userState = ref.watch(userStoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sprintCount = state.filteredMistakes.length > 5 ? 5 : state.filteredMistakes.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PrashnixColors.red.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.replay_rounded, color: PrashnixColors.red, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mistake Bank',
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!state.isLoading)
                  Text(
                    '${state.mistakes.length} mistakes to master',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMutedDark : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          // Hearts refill indicator badge in AppBar
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: PrashnixColors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PrashnixColors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  '${userState.heartCount}/5',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: PrashnixColors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          color: PrashnixColors.green,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          displacement: 40,
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: PrashnixColors.green))
              : Stack(
                  children: [
                    CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        if (state.mistakes.isNotEmpty) ...[
                          // Motivational Heart Recovery Banner
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                      : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFBBF7D0),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text('❤️', style: TextStyle(fontSize: 22)),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'हार्ट्स रिफिल करा • Practice & Refill',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: isDark ? Colors.white : const Color(0xFF14532D),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Clear 5 mistakes to earn +1 ❤️! Keep your streak strong.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? Colors.white70 : const Color(0xFF166534),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Filter Chips Bar
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 52,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: state.availableFilters.length,
                                itemBuilder: (context, index) {
                                  final filter = state.availableFilters[index];
                                  final isActive = filter == state.activeFilter;

                                  // Calculate count for this filter
                                  final count = filter == 'All'
                                      ? state.mistakes.length
                                      : state.mistakes.where((m) => m.question.formattedSubject == filter).length;

                                  return GestureDetector(
                                    onTap: () {
                                      if (ref.read(settingsProvider).hapticsEnabled) {
                                        HapticFeedback.selectionClick();
                                      }
                                      notifier.setFilter(filter);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? PrashnixColors.green
                                            : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isActive
                                              ? PrashnixColors.greenDarkBevel
                                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Text(
                                        '$filter ($count)',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: isActive
                                              ? Colors.white
                                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                                          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        // List of Mistake Cards
                        if (state.filteredMistakes.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(context),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 175), // Generous padding so last card clears the 3D button & nav bar
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  return MistakeCard(item: state.filteredMistakes[index]);
                                },
                                childCount: state.filteredMistakes.length,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Docked 3D Duolingo Action Button (Above Floating Nav Bar)
                    if (state.filteredMistakes.isNotEmpty)
                      Positioned(
                        bottom: 88, // Sits cleanly above the floating navbar
                        left: 20,
                        right: 20,
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _Prashnix3DButton(
                            text: 'QUICK SPRINT ($sprintCount MISTAKES) • +1 ❤️',
                            icon: Icons.bolt_rounded,
                            onTap: () => _startSprint(context, ref, count: 5),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: PrashnixColors.green.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_rounded, color: PrashnixColors.greenDarkBevel, size: 64),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
            const SizedBox(height: 24),
            Text(
              'Flawless!',
              style: AppTextStyles.h1.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You have zero pending mistakes.\nKeep up the perfect streak!",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Pull down to refresh",
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Prashnix3DButton extends StatefulWidget {
  final VoidCallback onTap;
  final String text;
  final IconData icon;

  const _Prashnix3DButton({
    required this.onTap,
    required this.text,
    required this.icon,
  });

  @override
  State<_Prashnix3DButton> createState() => _Prashnix3DButtonState();
}

class _Prashnix3DButtonState extends State<_Prashnix3DButton> {
  bool _isPressed = false;
  static const double _bevel = 4.0;
  static const double _height = 54.0;

  @override
  Widget build(BuildContext context) {
    final topOffset = _isPressed ? _bevel : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        height: _height + _bevel,
        child: Stack(
          children: [
            // Bottom 3D shadow bevel
            Positioned(
              top: _bevel,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: PrashnixColors.greenDarkBevel,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            // Top interactive face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              top: topOffset,
              left: 0,
              right: 0,
              bottom: _bevel - topOffset,
              child: Container(
                decoration: BoxDecoration(
                  color: PrashnixColors.green,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      widget.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
