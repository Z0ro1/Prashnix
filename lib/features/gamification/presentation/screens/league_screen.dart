import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/state/user_state.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../../domain/models/league_tier.dart';
import '../widgets/user_avatar.dart';
import '../widgets/district_selection_modal.dart';

/// Pixel-perfect, UX-friendly League / Leaderboard screen designed with 100% aesthetic
/// parity to the Profile Screen, featuring the unified Prashnix design system.
class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Refresh user profile and cloud rankings on screen mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userStoreProvider.notifier).refreshProfile();
      ref.read(leaderboardProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      HapticFeedback.selectionClick();
      final targetCategory = _tabController.index == 0
          ? LeaderboardCategory.xp
          : LeaderboardCategory.streak;
      ref.read(leaderboardProvider.notifier).setCategory(targetCategory);
    }
  }

  void _showLeagueRulesModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.primaryGreen, size: 28),
                const SizedBox(width: 10),
                Text(
                  'League System Guide',
                  style: AppTypography.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Compete with learners across your district and Maharashtra. Do daily lessons to gain XP, climb tiers, and unlock exclusive badges.',
              style: AppTypography.bodyMedium.copyWith(color: mutedColor),
            ),
            const SizedBox(height: 18),
            _buildRuleRow(
              icon: Icons.arrow_upward_rounded,
              color: AppColors.primaryGreen,
              title: 'Promotion Zone (Top 10)',
              subtitle: 'Advance to the next higher league at the end of each week.',
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 14),
            _buildRuleRow(
              icon: Icons.shield_rounded,
              color: AppColors.waterBlue,
              title: 'Safe Zone (Rank 11 - 25)',
              subtitle: 'Maintain your current league status for the upcoming week.',
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 14),
            _buildRuleRow(
              icon: Icons.bolt_rounded,
              color: AppColors.stepOrange,
              title: 'XP Multipliers & Streaks',
              subtitle: 'Flawless lessons award +120 XP, while milestone chests grant +100 XP.',
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('GOT IT', style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.headlineSmall.copyWith(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.labelMedium.copyWith(color: mutedColor)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);
    final userState = ref.watch(userStoreProvider);
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    // Determine current user's League Tier from real XP ground truth
    final userXp = userState.totalXp;
    final currentTier = LeagueTier.fromXp(userXp);
    final nextTier = currentTier.nextTier;
    final tierProgress = currentTier.progress(userXp);
    final xpNeeded = currentTier.xpNeededForNext(userXp);

    final districtName = state.selectedDistrict ??
        (userState.selectedDistrict.isNotEmpty && userState.selectedDistrict != 'Beginner District'
            ? userState.selectedDistrict
            : 'Nashik');

    final isStreakTab = state.category == LeaderboardCategory.streak;
    final currentRankNumber = isStreakTab ? state.currentUserStreakRank : state.currentUserRank;
    final rankText = currentRankNumber != null ? '#$currentRankNumber' : '#-';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Leagues',
          style: AppTypography.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            tooltip: 'League Rules',
            onPressed: () => _showLeagueRulesModal(context),
          ).animate().fade(),
          IconButton(
            icon: Icon(Icons.location_on_rounded, color: AppColors.primaryGreen),
            tooltip: 'Select District',
            onPressed: () {
              HapticFeedback.lightImpact();
              DistrictSelectionModal.show(
                context: context,
                currentDistrict: districtName,
                onDistrictSelected: (district) {
                  notifier.changeDistrict(district);
                },
              );
            },
          ).animate().fade(),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await Future.wait([
              notifier.refresh(),
              ref.read(userStoreProvider.notifier).refreshProfile(),
              SyncService().pullProgress(),
            ]);
          },
          color: AppColors.primaryGreen,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          displacement: 40,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildHeaderCard(
                    context: context,
                    currentTier: currentTier,
                    nextTier: nextTier,
                    tierProgress: tierProgress,
                    xpNeeded: xpNeeded,
                    userXp: userXp,
                    rankText: rankText,
                    isStreakTab: isStreakTab,
                    streakCount: userState.streakCount,
                    isDark: isDark,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    bgColor,
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryGreen,
                      indicatorWeight: 4,
                      dividerColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                      labelColor: AppColors.primaryGreenDark,
                      unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.bolt_rounded, size: 24),
                          text: 'XP League',
                        ),
                        Tab(
                          icon: Icon(Icons.local_fire_department_rounded, size: 24),
                          text: 'Top Streaks',
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                // Tab 0: XP League
                _buildXpLeagueTab(
                  context: context,
                  state: state,
                  notifier: notifier,
                  currentUserId: currentUserId,
                  userState: userState,
                  currentTier: currentTier,
                  districtName: districtName,
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ).animate().fade().slideX(begin: 0.1),

                // Tab 1: Top Streaks
                _buildStreakTab(
                  context: context,
                  state: state,
                  currentUserId: currentUserId,
                  userState: userState,
                  isDark: isDark,
                  textColor: textColor,
                  mutedColor: mutedColor,
                ).animate().fade().slideX(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Clean Hero Header Card matching ProfileScreen's _buildHeader layout
  Widget _buildHeaderCard({
    required BuildContext context,
    required LeagueTier currentTier,
    required LeagueTier? nextTier,
    required double tierProgress,
    required int xpNeeded,
    required int userXp,
    required String rankText,
    required bool isStreakTab,
    required int streakCount,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: AppCard(
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 90px Circular Tier Shield Emblem matching Profile's 90px Avatar
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [currentTier.primaryColor, currentTier.secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentTier.primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      currentTier.icon,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                const SizedBox(width: 20),

                // 3 Stats Columns with dividers matching ProfileScreen
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        currentTier.name.replaceAll(' League', ''),
                        'Tier ${currentTier.tierLevel}',
                        Icons.military_tech_rounded,
                        currentTier.primaryColor,
                        context,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      _buildStatColumn(
                        rankText,
                        'Your Rank',
                        Icons.leaderboard_rounded,
                        AppColors.waterBlue,
                        context,
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                      _buildStatColumn(
                        isStreakTab ? '$streakCount d' : '$userXp',
                        isStreakTab ? 'Streak' : 'Total XP',
                        isStreakTab ? Icons.local_fire_department_rounded : Icons.bolt_rounded,
                        isStreakTab ? AppColors.stepOrange : AppColors.primaryGreen,
                        context,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),
            Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight, height: 1),
            const SizedBox(height: 14),

            // Tier Progression Bar
            if (nextTier != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Next: ${nextTier.name}',
                        style: AppTypography.labelMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$xpNeeded XP to advance',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryGreenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: tierProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('👑 ', style: TextStyle(fontSize: 16)),
                  Text(
                    'Pinnacle League Reached! You are a Grandmaster.',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primaryGreenDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.2);
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color iconColor, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ],
    );
  }

  /// Tab 0: XP Leaderboard Content
  Widget _buildXpLeagueTab({
    required BuildContext context,
    required LeaderboardState state,
    required LeaderboardNotifier notifier,
    required String? currentUserId,
    required UserModel userState,
    required LeagueTier currentTier,
    required String districtName,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    final ranks = state.ranks;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                // Filter Segment (District vs Global)
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPillTab(
                        label: districtName,
                        icon: Icons.location_on_rounded,
                        isSelected: state.isDistrictMode,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          if (!state.isDistrictMode) {
                            notifier.toggleMode(true);
                          } else {
                            // Tap district again to switch district
                            DistrictSelectionModal.show(
                              context: context,
                              currentDistrict: districtName,
                              onDistrictSelected: (district) {
                                notifier.changeDistrict(district);
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      _buildPillTab(
                        label: 'Global',
                        icon: Icons.public_rounded,
                        isSelected: !state.isDistrictMode,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.toggleMode(false);
                        },
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Live status tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live Ranks',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primaryGreenDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Promotion Zone Callout
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryGreen.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_upward_rounded, color: AppColors.primaryGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Top 10 contenders advance to the next league every Sunday!',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.primaryGreenDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Ranks List
        if (state.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
          )
        else if (ranks.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No Contenders Yet in $districtName',
              subtitle: 'Complete your daily lessons to claim the #1 spot on the leaderboard!',
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rankData = ranks[index];
                  final rank = index + 1;
                  final isMe = rankData['id'] == currentUserId;
                  final realXp = (rankData['total_xp'] as num?)?.toInt() ?? (rankData['weekly_xp'] as num?)?.toInt() ?? 0;
                  final displayXp = isMe ? (realXp > userState.totalXp ? realXp : userState.totalXp) : realXp;

                  return _buildLeaderboardRowCard(
                    rank: rank,
                    username: rankData['username'] ?? 'Learner',
                    avatarId: isMe ? userState.avatarId : rankData['avatar_id'],
                    district: rankData['district'] ?? districtName,
                    metricText: '+${NumberFormat.decimalPattern().format(displayXp)} XP',
                    metricColor: AppColors.primaryGreenDark,
                    metricBgColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                    isMe: isMe,
                    isDark: isDark,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ).animate().fade(duration: 250.ms, delay: (index < 12 ? (index * 30).ms : 0.ms)).slideY(begin: 0.08, curve: Curves.easeOutCubic);
                },
                childCount: ranks.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Tab 1: Streaks Leaderboard Content
  Widget _buildStreakTab({
    required BuildContext context,
    required LeaderboardState state,
    required String? currentUserId,
    required UserModel userState,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    final ranks = state.streakRanks;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded, color: AppColors.stepOrange, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Top 10 Daily Streak Champions',
                  style: AppTypography.headlineSmall.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator(color: AppColors.stepOrange)),
          )
        else if (ranks.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.local_fire_department_outlined,
              title: 'No Active Streaks Found',
              subtitle: 'Practice consistently every single day to climb the streak championship!',
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final rankData = ranks[index];
                  final rank = index + 1;
                  final isMe = rankData['id'] == currentUserId;
                  final realStreak = (rankData['streak_count'] as num?)?.toInt() ?? 0;
                  final displayStreak = isMe ? (realStreak > userState.streakCount ? realStreak : userState.streakCount) : realStreak;

                  return _buildLeaderboardRowCard(
                    rank: rank,
                    username: rankData['username'] ?? 'Learner',
                    avatarId: isMe ? userState.avatarId : rankData['avatar_id'],
                    district: rankData['district'] ?? 'Maharashtra',
                    metricText: '🔥 $displayStreak ${displayStreak == 1 ? "Day" : "Days"}',
                    metricColor: AppColors.stepOrange,
                    metricBgColor: AppColors.stepOrange.withValues(alpha: 0.15),
                    isMe: isMe,
                    isDark: isDark,
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ).animate().fade(duration: 250.ms, delay: (index < 12 ? (index * 30).ms : 0.ms)).slideY(begin: 0.08, curve: Curves.easeOutCubic);
                },
                childCount: ranks.length,
              ),
            ),
          ),
      ],
    );
  }

  /// Reusable Leaderboard Row Card matching AppCard aesthetics
  Widget _buildLeaderboardRowCard({
    required int rank,
    required String username,
    required String? avatarId,
    required String district,
    required String metricText,
    required Color metricColor,
    required Color metricBgColor,
    required bool isMe,
    required bool isDark,
    required Color textColor,
    required Color mutedColor,
  }) {
    // Medal badges for podium ranks
    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 26);
    } else if (rank == 2) {
      rankWidget = const Icon(Icons.military_tech_rounded, color: Color(0xFF94A3B8), size: 26);
    } else if (rank == 3) {
      rankWidget = const Icon(Icons.military_tech_rounded, color: Color(0xFFCD7F32), size: 26);
    } else {
      rankWidget = Text(
        '#$rank',
        textAlign: TextAlign.center,
        style: AppTypography.headlineSmall.copyWith(
          color: mutedColor,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final cardBg = isMe
        ? (isDark ? AppColors.primaryGreen.withValues(alpha: 0.12) : const Color(0xFFF0FDF4))
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);

    final borderColor = isMe
        ? AppColors.primaryGreen
        : (isDark ? AppColors.borderDark : AppColors.borderLight);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isMe ? 2 : 1,
        ),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Row(
        children: [
          // Rank Badge
          SizedBox(
            width: 32,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 10),

          // Contender Avatar
          UserAvatar(
            avatarId: avatarId,
            username: username,
            size: 42,
            borderColor: isMe ? AppColors.primaryGreen : null,
            borderWidth: isMe ? 2 : 0,
          ),
          const SizedBox(width: 12),

          // User Info & District
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: AppTypography.headlineSmall.copyWith(
                          color: textColor,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: AppColors.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  district,
                  style: AppTypography.labelMedium.copyWith(color: mutedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Metric Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: metricBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              metricText,
              style: AppTypography.labelLarge.copyWith(
                color: metricColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.backgroundDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.4))
              : null,
          boxShadow: isSelected && !isDark ? AppColors.softCardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? AppColors.primaryGreen
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                    : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: mutedColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Persistent Header Delegate for TabBar matching ProfileScreen exactly
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.bgColor, this._tabBar);

  final Color bgColor;
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
