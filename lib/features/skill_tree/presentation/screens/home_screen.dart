import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/state/user_state.dart';
import '../../../../features/gamification/presentation/providers/heart_economy_provider.dart';
import '../../../../features/gamification/presentation/widgets/heart_refill_modal_sheet.dart';
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

/// Pixel-perfect Prashnix Home / Learning Path Screen integrated with full backend logic.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
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

  void _showHeartsModal(int currentHearts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                'Hearts: $currentHearts / 5',
                style: TextStyle(
                  fontFamily: PrashnixTextStyles.prashnixSans,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hearts refill 1 per hour (or fully at midnight IST). You can also practice your mistakes to earn back hearts!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: PrashnixTextStyles.prashnixSans,
                  color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
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
              const SizedBox(height: 12),
              // Watch Ad Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: PrashnixColors.green,
                  side: const BorderSide(color: PrashnixColors.green, width: 2),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  final success = await ref.read(heartEconomyProvider.notifier).rewardAdWatched();
                  if (!mounted) return;
                  if (success) {
                    PrashnixAudioService.playStarChime();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('+2 Hearts Claimed!', style: TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: PrashnixColors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Daily rewarded ad limit reached (Max 4/day).', style: TextStyle(fontWeight: FontWeight.bold)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
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
          ),
        ),
      ),
    );
  }

  void _showChestRewardModal() {
    PrashnixAudioService.playGemsReward();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
              'Outstanding work mastering this section! You claimed +25 XP bonus!',
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
              onPressed: () {
                ref.read(userStoreProvider.notifier).addXp(25);
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'CLAIM REWARD',
                style: TextStyle(
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
  }

  void _onActiveNodeTap(SkillNode node) {
    PrashnixAudioService.playStarChime();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
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
                        const Text(
                          'READY FOR LESSON?',
                          style: TextStyle(
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
                'Complete questions to extend your streak shield and claim +25 XP!',
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
                  if (ref.read(settingsProvider).hapticsEnabled) {
                    HapticFeedback.mediumImpact();
                  }
                  Navigator.of(ctx).pop();

                  final hasEnoughHearts = ref.read(heartEconomyProvider.notifier).attemptLessonLaunch();
                  if (hasEnoughHearts) {
                    ref.read(quizProvider.notifier).loadQuestionsForNode(node.id);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const QuizScreen()),
                    );
                  } else {
                    _showHeartsModal(ref.read(userStoreProvider).heartCount);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "LET'S GO",
                      style: TextStyle(
                        fontFamily: PrashnixTextStyles.dinNext,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onCompletedNodeTap(SkillNode node) {
    PrashnixAudioService.playNodeComplete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PrashnixColors.yellowShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Completed: ${node.title} (Cleared!)',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
      return Positioned(
        top: cy - 88, // Centers the 88px ring at cy, placing tooltip cleanly above
        left: cx - 100,
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrashnixFloatingTooltip(
              text: 'START +25 XP',
              textColor: unitColor,
            ),
            const SizedBox(height: 6),
            PrashnixPulsingRing(
              size: 88,
              pulseColor: unitColor,
              child: PrashnixPathNode(
                type: PrashnixNodeType.activeStar,
                size: 84,
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
            _showChestRewardModal();
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
