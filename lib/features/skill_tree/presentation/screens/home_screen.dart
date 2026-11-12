import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/user_state.dart';
import '../../../../features/gamification/presentation/providers/heart_economy_provider.dart';
import '../../../../features/gamification/domain/services/heart_engine_service.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../features/gamification/presentation/widgets/heart_refill_modal_sheet.dart';
import '../../../../features/gamification/presentation/widgets/heart_regen_timer_widget.dart';
import '../../../../features/quiz/presentation/providers/quiz_provider.dart';
import '../../../../features/quiz/presentation/screens/quiz_screen.dart';
import '../../../../features/leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../../../features/profile/presentation/providers/settings_provider.dart';
import '../components/prashnix_audio_service.dart';
import '../components/prashnix_floating_tooltip.dart';
import '../components/prashnix_path_node.dart';
import '../components/prashnix_pulsing_ring.dart';
import '../components/prashnix_stats_bar.dart';
import '../components/prashnix_stepping_dots.dart';
import '../components/prashnix_unit_header.dart';
import '../providers/skill_tree_provider.dart';
import '../../data/repositories/sync_service.dart';
import '../theme/prashnix_colors.dart';
import '../theme/prashnix_text_styles.dart';
import '../../../profile/data/repositories/progress_repository.dart';

/// Pixel-perfect Prashnix Home / Learning Path Screen integrated with full backend logic.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isLaunchingLesson = false;

  // Pattern of X horizontal offsets for Prashnix S-curve path
  static const List<double> _pathCurveOffsets = [
    0.0,    // Center
    55.0,   // Right
    55.0,   // Right
    0.0,    // Center
    -55.0,  // Left
    -55.0,  // Left
  ];

  void _showDistrictSelector() {
    final currentDistrict = ref.read(userStoreProvider).selectedDistrict;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Target District',
                    style: TextStyle(
                      fontFamily: PrashnixTextStyles.prashnixSans,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: LeaderboardNotifier.maharashtraDistricts.length,
                  itemBuilder: (context, index) {
                    final district = LeaderboardNotifier.maharashtraDistricts[index];
                    final isSelected = district == currentDistrict;

                    return ListTile(
                      leading: const Icon(Icons.location_on_rounded, color: PrashnixColors.green),
                      title: Text(
                        district,
                        style: TextStyle(
                          fontFamily: PrashnixTextStyles.dinNext,
                          fontSize: 16,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                          color: isSelected 
                              ? PrashnixColors.green 
                              : (isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary),
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: PrashnixColors.green)
                          : null,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        PrashnixAudioService.playTap();
                        ref.read(userStoreProvider.notifier).updateProfile(selectedDistrict: district);
                        Navigator.of(ctx).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInsufficientHeartsPopup() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentHearts = ref.read(userStoreProvider).heartCount;
    final dailyAdCount = await ref.read(heartEconomyProvider.notifier).getDailyHeartAdCount();
    const maxAds = HeartEconomy.maxDailyHeartAds;
    final remainingAds = (maxAds - dailyAdCount).clamp(0, maxAds);
    final canWatch = remainingAds > 0;

    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    bool isLoadingAd = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Heart Icon
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: PrashnixColors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('💔', style: TextStyle(fontSize: 36)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Need 2 Hearts to Play!',
                  style: TextStyle(
                    fontFamily: PrashnixTextStyles.prashnixSans,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Each lesson costs 2 hearts. You currently have $currentHearts / 5 ❤️.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: PrashnixTextStyles.prashnixSans,
                    color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Daily Ad Counter Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: canWatch 
                        ? PrashnixColors.green.withValues(alpha: 0.12)
                        : PrashnixColors.textSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canWatch 
                          ? PrashnixColors.green.withValues(alpha: 0.3)
                          : PrashnixColors.textSecondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        canWatch ? Icons.ondemand_video_rounded : Icons.block_rounded,
                        size: 18,
                        color: canWatch ? PrashnixColors.green : PrashnixColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        canWatch
                            ? 'Daily Ads: $dailyAdCount / $maxAds ($remainingAds left)'
                            : 'Daily ad limit reached (Max 4/day)',
                        style: TextStyle(
                          fontFamily: PrashnixTextStyles.dinNext,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: canWatch ? PrashnixColors.green : PrashnixColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Watch Ad Action
                if (canWatch) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PrashnixColors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: isLoadingAd
                        ? null
                        : () async {
                            final dialogNav = Navigator.of(dialogCtx);
                            setDialogState(() => isLoadingAd = true);
                            
                            await AdMobService().showRewardedAd(
                              type: AdRewardType.heartRefill,
                              currentHearts: currentHearts,
                              onAdClosed: () {
                                if (dialogCtx.mounted) {
                                  setDialogState(() => isLoadingAd = false);
                                }
                              },
                              onEarnedReward: () async {
                                final success = await ref.read(heartEconomyProvider.notifier).rewardAdWatched();
                                if (dialogCtx.mounted && dialogNav.canPop()) {
                                  dialogNav.pop();
                                }
                                if (mounted) {
                                  if (success) {
                                    PrashnixAudioService.playStarChime();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: PrashnixColors.green,
                                        content: Text(
                                          '+2 Hearts Earned! You now have ${ref.read(userStoreProvider).heartCount} ❤️',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    );
                                  } else {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        content: Text('Could not claim hearts. Daily ad limit reached or hearts full.'),
                                      ),
                                    );
                                  }
                                }
                              },
                              onError: (err) async {
                                if (dialogCtx.mounted) {
                                  setDialogState(() => isLoadingAd = false);
                                }
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      content: Text(err),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.ondemand_video_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          isLoadingAd ? 'LOADING AD...' : 'WATCH AD (+2 ❤️)',
                          style: const TextStyle(
                            fontFamily: PrashnixTextStyles.dinNext,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'You have watched all 4 ads for today.\nHearts refill 1 every 2 hours or fully at midnight IST.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: PrashnixTextStyles.prashnixSans,
                      fontSize: 13,
                      color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    'CLOSE',
                    style: TextStyle(
                      fontFamily: PrashnixTextStyles.dinNext,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showHeartsModal(int currentHearts) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyAdCount = await ref.read(heartEconomyProvider.notifier).getDailyHeartAdCount();
    const maxAds = HeartEconomy.maxDailyHeartAds;
    final remainingAds = (maxAds - dailyAdCount).clamp(0, maxAds);
    final isFull = currentHearts >= HeartEngineService.maxHearts;
    final canWatch = remainingAds > 0 && !isFull;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 8),
                Text(
                  'Hearts: $currentHearts / 5',
                  style: TextStyle(
                    fontFamily: PrashnixTextStyles.prashnixSans,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                  ),
                ),
                if (currentHearts < 5) ...[
                  const SizedBox(height: 6),
                  const HeartRegenTimerWidget(),
                ],
                const SizedBox(height: 8),
                Text(
                  'Each lesson costs 2 hearts. Hearts refill 1 per 2 hours (or fully at midnight IST). No hearts lost on wrong answers!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: PrashnixTextStyles.prashnixSans,
                    color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                // Daily Ads Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: canWatch 
                        ? PrashnixColors.green.withValues(alpha: 0.12)
                        : PrashnixColors.textSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isFull
                        ? 'Hearts are full (5/5) ❤️'
                        : canWatch
                            ? 'Daily Rewarded Ads: $dailyAdCount / $maxAds ($remainingAds remaining)'
                            : 'Daily limit reached (Max 4/day)',
                    style: TextStyle(
                      fontFamily: PrashnixTextStyles.dinNext,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: canWatch ? PrashnixColors.green : PrashnixColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Practice Mistakes Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PrashnixColors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    PrashnixAudioService.playTap();
                    HeartRefillModalSheet.show(context);
                  },
                  child: const Text(
                    'REFILL OPTIONS & PRACTICE',
                    style: TextStyle(
                      fontFamily: PrashnixTextStyles.dinNext,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                // Watch Ad Button
                if (canWatch) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PrashnixColors.green,
                      side: const BorderSide(color: PrashnixColors.green, width: 2),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await AdMobService().showRewardedAd(
                        type: AdRewardType.heartRefill,
                        currentHearts: currentHearts,
                        onEarnedReward: () async {
                          final success = await ref.read(heartEconomyProvider.notifier).rewardAdWatched();
                          if (!mounted) return;
                          if (success) {
                            PrashnixAudioService.playStarChime();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: PrashnixColors.green,
                                content: Text(
                                  '+2 Hearts Claimed! (${ref.read(userStoreProvider).heartCount} ❤️)',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('Could not claim hearts. Daily ad limit reached or hearts full.'),
                              ),
                            );
                          }
                        },
                        onError: (err) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text(err),
                              ),
                            );
                          }
                        },
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ondemand_video_rounded, color: PrashnixColors.green),
                        SizedBox(width: 8),
                        Text(
                          'WATCH AD (+2 ❤️)',
                          style: TextStyle(
                            fontFamily: PrashnixTextStyles.dinNext,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
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
      ),
    );
  }

  void _showChestRewardModal(SkillNode node) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = ProgressRepository();
    final claimKey = 'chest_claimed_${node.id}';
    final alreadyClaimed = (await repo.getLocalState(claimKey)) == '1';

    if (!mounted) return;

    if (alreadyClaimed) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'Milestone Completed!',
                style: TextStyle(
                  fontFamily: PrashnixTextStyles.prashnixSans,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have already claimed your +100 XP bonus for this milestone chest. Keep learning to unlock new sections!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: PrashnixTextStyles.prashnixSans,
                  color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMint,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
      return;
    }

    PrashnixAudioService.playGemsReward();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isClaiming = false;
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎁', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Milestone Chest Unlocked!',
                  style: TextStyle(
                    fontFamily: PrashnixTextStyles.prashnixSans,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Outstanding work mastering this section! Claim your +100 XP milestone bonus!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: PrashnixTextStyles.prashnixSans,
                    color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PrashnixColors.yellow,
                    foregroundColor: Colors.black87,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isClaiming
                      ? null
                      : () async {
                          setDialogState(() => isClaiming = true);
                          await repo.saveLocalState(claimKey, '1');
                          ref.read(userStoreProvider.notifier).addXp(100);
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                        },
                  child: Text(
                    isClaiming ? 'CLAIMING...' : 'CLAIM REWARD (+100 XP)',
                    style: const TextStyle(
                      fontFamily: PrashnixTextStyles.dinNext,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onActiveNodeTap(SkillNode node) {
    PrashnixAudioService.playStarChime();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLessonIndex = node.completedLessons;
    final lessonNumber = currentLessonIndex + 1;
    final totalLessons = node.totalLessons;
    
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: PrashnixColors.green,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LESSON $lessonNumber OF $totalLessons',
                          style: const TextStyle(
                            fontFamily: PrashnixTextStyles.dinNext,
                            color: PrashnixColors.greenShadow,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.title,
                          style: TextStyle(
                            fontFamily: PrashnixTextStyles.prashnixSans,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Complete questions to extend your streak shield and claim +25 XP! Cost: 2 ❤️.',
                style: TextStyle(
                  fontFamily: PrashnixTextStyles.prashnixSans,
                  color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PrashnixColors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (_isLaunchingLesson) return;
                  _isLaunchingLesson = true;

                  if (ref.read(settingsProvider).hapticsEnabled) {
                    HapticFeedback.mediumImpact();
                  }
                  Navigator.of(ctx).pop();

                  final hasEnoughHearts = ref.read(heartEconomyProvider.notifier).attemptLessonLaunch();
                  if (hasEnoughHearts) {
                    ref.read(quizProvider.notifier).loadQuestionsForNode(node.id, lessonIndex: currentLessonIndex);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    ).then((_) {
                      _isLaunchingLesson = false;
                      ref.read(quizProvider.notifier).resetQuiz();
                    });
                  } else {
                    _isLaunchingLesson = false;
                    _showInsufficientHeartsPopup();
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "START LESSON $lessonNumber (2 ❤️)",
                      style: const TextStyle(
                        fontFamily: PrashnixTextStyles.dinNext,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _onCompletedNodeTap(SkillNode node) {
    PrashnixAudioService.playStarChime();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: PrashnixColors.yellow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRACTICE COMPLETED NODE',
                          style: TextStyle(
                            fontFamily: PrashnixTextStyles.dinNext,
                            color: PrashnixColors.yellowShadow,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          node.title,
                          style: TextStyle(
                            fontFamily: PrashnixTextStyles.prashnixSans,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.close, color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'You have completed all lessons in this node! You can practice again anytime to sharpen your skills. Cost: 2 ❤️.',
                style: TextStyle(
                  fontFamily: PrashnixTextStyles.prashnixSans,
                  color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PrashnixColors.yellowShadow,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (_isLaunchingLesson) return;
                  _isLaunchingLesson = true;

                  if (ref.read(settingsProvider).hapticsEnabled) {
                    HapticFeedback.mediumImpact();
                  }
                  Navigator.of(ctx).pop();

                  final hasEnoughHearts = ref.read(heartEconomyProvider.notifier).attemptLessonLaunch();
                  if (hasEnoughHearts) {
                    ref.read(quizProvider.notifier).loadQuestionsForNode(node.id, lessonIndex: 0);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    ).then((_) {
                      _isLaunchingLesson = false;
                      ref.read(quizProvider.notifier).resetQuiz();
                    });
                  } else {
                    _isLaunchingLesson = false;
                    _showInsufficientHeartsPopup();
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "PRACTICE AGAIN (2 ❤️)",
                      style: TextStyle(
                        fontFamily: PrashnixTextStyles.dinNext,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.replay_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  void _onLockedNodeTap(SkillNode node) {
    HapticFeedback.heavyImpact();
    PrashnixAudioService.playTap();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PrashnixColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Complete previous lessons to unlock "${node.title}".',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    try {
      await Future.wait([
        ref.read(userStoreProvider.notifier).refreshProfile(),
        SyncService().pullProgress(),
      ]);
      ref.invalidate(skillTreeProvider);
      await ref.read(skillTreeProvider.future);
    } catch (e) {
      debugPrint('HomeScreen refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userStoreProvider);
    final unitsAsync = ref.watch(skillTreeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: PrashnixStatsBar(
        streakDays: userState.streakCount,
        gems: userState.totalXp,
        hearts: userState.heartCount,
        languageFlag: '📍 ${userState.selectedDistrict}',
        onFlagTap: _showDistrictSelector,
        onHeartsTap: () => _showHeartsModal(userState.heartCount),
        onGemsTap: () {
          PrashnixAudioService.playGemsReward();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: PrashnixColors.blue,
              content: Text(
                'Total XP: ${userState.totalXp} XP! Keep earning XP to climb the ranks.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
        onStreakTap: () {
          PrashnixAudioService.playStreakFlame();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: PrashnixColors.orange,
              content: Text(
                '🔥 ${userState.streakCount} Day Streak! Practice daily to protect your flame.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: PrashnixColors.green,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        displacement: 40,
        child: unitsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: PrashnixColors.green),
          ),
          error: (err, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: PrashnixColors.red, size: 52),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading curriculum: $err',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PrashnixColors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: _handleRefresh,
                    child: const Text('RETRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
          data: (units) {
            if (units.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 64,
                        color: isDark ? AppColors.textSecondaryDark : PrashnixColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No curriculum units available.',
                        style: TextStyle(
                          fontFamily: PrashnixTextStyles.prashnixSans,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pull down to reload curriculum.',
                        style: TextStyle(
                          fontFamily: PrashnixTextStyles.prashnixSans,
                          fontSize: 14,
                          color: isDark ? AppColors.textSecondaryDark : PrashnixColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Column(
                children: [
                  for (int u = 0; u < units.length; u++) ...[
                    // 1. Dynamic Beveled Unit Header Card matching Admin Dashboard Theme Color
                    PrashnixUnitHeader(
                      unitNumber: units[u].unitNumber,
                      title: units[u].title,
                      description: 'Master your skills, level up, and prepare for exams.',
                      color: _parseHexColor(units[u].colorHex),
                      onGuidebookTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              'Guidebook: ${units[u].title} - Key concepts & notes',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // 2. The Learning Path Nodes & Stepping Dots
                    _buildUnitPath(
                      context,
                      units[u],
                      _parseHexColor(units[u].colorHex),
                    ),

                    const SizedBox(height: 32),
                  ],
                  // Padding for floating bottom navigation bar
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _parseHexColor(String? hexString, [Color fallback = PrashnixColors.green]) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      String cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Widget _buildUnitPath(BuildContext context, SkillUnit unit, Color unitColor) {
    final nodes = unit.nodes;
    if (nodes.isEmpty) return const SizedBox.shrink();

    // Constant geometry configuration
    const double topPadding = 90.0;
    const double nodeSpacing = 135.0;
    final double pathHeight = topPadding + (nodes.length * nodeSpacing) + 20.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double centerX = screenWidth / 2;

    return SizedBox(
      height: pathHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Render stepping dots between node i and node i + 1
          for (int i = 0; i < nodes.length - 1; i++) ...[
            _buildSteppingDotsBetween(
              index: i,
              centerX: centerX,
              topPadding: topPadding,
              nodeSpacing: nodeSpacing,
              nodeA: nodes[i],
              nodeB: nodes[i + 1],
            ),
          ],

          // 2. Render each Node on the path
          for (int i = 0; i < nodes.length; i++) ...[
            _buildPathNodeItem(
              context: context,
              node: nodes[i],
              index: i,
              centerX: centerX,
              topPadding: topPadding,
              nodeSpacing: nodeSpacing,
              unitColor: unitColor,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSteppingDotsBetween({
    required int index,
    required double centerX,
    required double topPadding,
    required double nodeSpacing,
    required SkillNode nodeA,
    required SkillNode nodeB,
  }) {
    final double offsetA = _pathCurveOffsets[index % _pathCurveOffsets.length];
    final double offsetB = _pathCurveOffsets[(index + 1) % _pathCurveOffsets.length];

    final double cxA = centerX + offsetA;
    final double cyA = topPadding + (index * nodeSpacing);
    final double cxB = centerX + offsetB;
    final double cyB = topPadding + ((index + 1) * nodeSpacing);

    final double dx = cxB - cxA;
    final double dy = cyB - cyA;
    final double dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0) return const SizedBox.shrink();

    final double ux = dx / dist;
    final double uy = dy / dist;

    // Node outer radii with safety clearance margin
    final bool isAActive = nodeA.status == NodeStatus.active;
    final bool isBActive = nodeB.status == NodeStatus.active;
    final double radiusA = (isAActive ? 44.0 : 40.0) + 8.0;
    final double radiusB = (isBActive ? 44.0 : 40.0) + 8.0;

    final Offset startPoint = Offset(cxA + ux * radiusA, cyA + uy * radiusA);
    final Offset endPoint = Offset(cxB - ux * radiusB, cyB - uy * radiusB);

    return Positioned.fill(
      child: PrashnixSteppingDots(
        count: 3,
        startOffset: startPoint,
        endOffset: endPoint,
      ),
    );
  }

  Widget _buildPathNodeItem({
    required BuildContext context,
    required SkillNode node,
    required int index,
    required double centerX,
    required double topPadding,
    required double nodeSpacing,
    required Color unitColor,
  }) {
    final double offset = _pathCurveOffsets[index % _pathCurveOffsets.length];
    final double cx = centerX + offset;
    final double cy = topPadding + (index * nodeSpacing);

    PrashnixNodeType nodeType;
    if (node.status == NodeStatus.completed) {
      nodeType = node.type == NodeType.milestone
          ? PrashnixNodeType.completedChest
          : PrashnixNodeType.completedCheck;
    } else if (node.status == NodeStatus.active) {
      nodeType = PrashnixNodeType.activeStar;
    } else {
      nodeType = PrashnixNodeType.locked;
    }

    if (nodeType == PrashnixNodeType.activeStar) {
      final totalLessons = node.totalLessons > 0 ? node.totalLessons : 1;
      final completedLessons = node.completedLessons.clamp(0, totalLessons);
      final currentLessonNumber = (completedLessons + 1).clamp(1, totalLessons);

      final String tooltipText = completedLessons > 0
          ? 'LESSON $currentLessonNumber OF $totalLessons'
          : 'START LESSON';

      return Positioned(
        top: cy - 119, // Centers the 80px node button at cy with 10px ring spacing
        left: cx - 110,
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrashnixFloatingTooltip(
              text: tooltipText,
              textColor: unitColor,
            ),
            const SizedBox(height: 8),
            PrashnixPulsingRing(
              size: 114, // 10px clean breathing space between node button (80px) and ring
              totalLessons: totalLessons,
              completedLessons: completedLessons,
              pulseColor: unitColor,
              child: PrashnixPathNode(
                type: PrashnixNodeType.activeStar,
                size: 80,
                activeColor: unitColor,
                onTap: () => _onActiveNodeTap(node),
              ),
            ),
          ],
        ),
      );
    }

    return Positioned(
      top: cy - 40,
      left: cx - 40,
      child: PrashnixPathNode(
        type: nodeType,
        size: 80,
        activeColor: unitColor,
        onTap: () {
          if (nodeType == PrashnixNodeType.completedChest) {
            _showChestRewardModal(node);
          } else if (node.status == NodeStatus.completed) {
            _onCompletedNodeTap(node);
          } else {
            _onLockedNodeTap(node);
          }
        },
      ),
    );
  }
}
