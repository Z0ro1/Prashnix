import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/state/user_state.dart';
import '../../../leaderboard/presentation/providers/leaderboard_provider.dart';
import '../../domain/models/league_tier.dart';
import '../widgets/user_avatar.dart';
import '../widgets/district_selection_modal.dart';

class LeagueScreen extends ConsumerStatefulWidget {
  const LeagueScreen({super.key});

  @override
  ConsumerState<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends ConsumerState<LeagueScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure user profile is up-to-date with Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userStoreProvider.notifier).refreshProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);
    final userState = ref.watch(userStoreProvider);
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0F141C) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textMuted = isDark ? Colors.white60 : const Color(0xFF64748B);

    // Determine current user's League Tier from their real XP
    final userXp = userState.totalXp;
    final currentTier = LeagueTier.fromXp(userXp);
    final nextTier = currentTier.nextTier;
    final tierProgress = currentTier.progress(userXp);
    final xpNeeded = currentTier.xpNeededForNext(userXp);

    final districtName = state.selectedDistrict ?? 
        (userState.selectedDistrict.isNotEmpty && userState.selectedDistrict != 'Beginner District'
            ? userState.selectedDistrict 
            : 'Nashik');

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Category Switcher (XP vs Streaks) ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2430) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _CategoryTab(
                        label: 'XP League',
                        icon: Icons.bolt_rounded,
                        activeColor: currentTier.primaryColor,
                        isSelected: state.category == LeaderboardCategory.xp,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setCategory(LeaderboardCategory.xp);
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _CategoryTab(
                        label: 'Top Streaks 🔥',
                        icon: Icons.local_fire_department_rounded,
                        activeColor: const Color(0xFFFF9600),
                        isSelected: state.category == LeaderboardCategory.streak,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.setCategory(LeaderboardCategory.streak);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hero Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: state.category == LeaderboardCategory.xp
                  ? _buildLeagueHeader(
                      context: context,
                      isDark: isDark,
                      currentTier: currentTier,
                      nextTier: nextTier,
                      userXp: userXp,
                      tierProgress: tierProgress,
                      xpNeeded: xpNeeded,
                      username: userState.username.isNotEmpty ? userState.username : 'Contender',
                      avatarId: userState.avatarId,
                      myRank: state.currentUserRank,
                      isDistrictMode: state.isDistrictMode,
                      districtName: districtName,
                    )
                  : _buildStreakHeader(
                      context: context,
                      isDark: isDark,
                      userStreak: userState.streakCount,
                      username: userState.username.isNotEmpty ? userState.username : 'Contender',
                      avatarId: userState.avatarId,
                      myStreakRank: state.currentUserStreakRank,
                    ),
            ),

            // ── Filter Controls (Only for XP League) ─────────────────────
            if (state.category == LeaderboardCategory.xp)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    // Mode Switcher Pill
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B2430) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _FilterTab(
                            label: 'District',
                            icon: Icons.location_on_rounded,
                            isSelected: state.isDistrictMode,
                            isDark: isDark,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              notifier.toggleMode(true);
                            },
                          ),
                          _FilterTab(
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

                    // District Selector Button (when in district mode)
                    if (state.isDistrictMode)
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          DistrictSelectionModal.show(
                            context: context,
                            currentDistrict: districtName,
                            onDistrictSelected: (district) {
                              notifier.changeDistrict(district);
                            },
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2430) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFCBD5E1),
                            ),
                            boxShadow: isDark
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pin_drop_rounded,
                                size: 15,
                                color: AppColors.primaryGreen,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  districtName,
                                  style: AppTextStyles.label.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Top Notice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Text(
                    state.category == LeaderboardCategory.xp
                        ? (state.isDistrictMode ? 'Top 30 in $districtName' : 'Top 30 Global Leaders')
                        : 'Top 10 Longest Streaks 🔥',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: state.category == LeaderboardCategory.xp
                          ? AppColors.primaryGreen.withValues(alpha: 0.12)
                          : const Color(0xFFFF9600).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      state.category == LeaderboardCategory.xp ? 'Live Ranks' : 'Global • All Users',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: state.category == LeaderboardCategory.xp
                            ? (isDark ? AppColors.greenLight : AppColors.primaryGreenDark)
                            : const Color(0xFFFF9600),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // ── Leaderboard List (Top 30 XP or Top 10 Streaks) ───────────
            Expanded(
              child: state.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: state.category == LeaderboardCategory.xp
                            ? currentTier.primaryColor
                            : const Color(0xFFFF9600),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        HapticFeedback.mediumImpact();
                        await Future.wait([
                          notifier.refresh(),
                          ref.read(userStoreProvider.notifier).refreshProfile(),
                        ]);
                      },
                      color: state.category == LeaderboardCategory.xp
                          ? AppColors.primaryGreen
                          : const Color(0xFFFF9600),
                      backgroundColor: isDark ? const Color(0xFF1B2430) : Colors.white,
                      displacement: 20,
                      child: (state.category == LeaderboardCategory.xp ? state.ranks : state.streakRanks).isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                                Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        state.category == LeaderboardCategory.xp
                                            ? Icons.emoji_events_outlined
                                            : Icons.local_fire_department_outlined,
                                        size: 56,
                                        color: textMuted.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        state.category == LeaderboardCategory.xp
                                            ? 'No contenders yet in $districtName'
                                            : 'No active streaks recorded yet',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        state.category == LeaderboardCategory.xp
                                            ? 'Complete lessons to earn XP and take the #1 spot!'
                                            : 'Practice daily to take the #1 Streak Master spot!',
                                        style: TextStyle(
                                          color: textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(16, 6, 16, 110),
                              itemCount: state.category == LeaderboardCategory.xp
                                  ? state.ranks.length
                                  : state.streakRanks.length,
                              itemBuilder: (context, index) {
                                final isStreak = state.category == LeaderboardCategory.streak;
                                final rankData = isStreak
                                    ? state.streakRanks[index]
                                    : state.ranks[index];
                                final rank = index + 1;
                                final isMe = rankData['id'] == currentUserId;
                                
                                final userRealXp = (rankData['total_xp'] as num?)?.toInt() ?? 
                                    (rankData['weekly_xp'] as num?)?.toInt() ?? 0;
                                final displayXp = isMe ? (userRealXp > userXp ? userRealXp : userXp) : userRealXp;

                                final userRealStreak = (rankData['streak_count'] as num?)?.toInt() ?? 0;
                                final displayStreak = isMe
                                    ? (userRealStreak > userState.streakCount ? userRealStreak : userState.streakCount)
                                    : userRealStreak;

                                return _LeaderboardRankCard(
                                  key: ValueKey('${isStreak ? "streak" : "xp"}_${rankData['id'] ?? index}'),
                                  rank: rank,
                                  username: rankData['username'] ?? 'Learner',
                                  avatarId: isMe ? userState.avatarId : rankData['avatar_id'],
                                  district: rankData['district'],
                                  xp: displayXp,
                                  streak: displayStreak,
                                  isStreakMode: isStreak,
                                  isMe: isMe,
                                  isDark: isDark,
                                  showDistrictBadge: isStreak || !state.isDistrictMode,
                                ).animate()
                                 .fade(duration: 300.ms, delay: (index < 10 ? index * 30 : 0).ms)
                                 .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refined League & User Hero Header without ugly glows or square artifacts
  Widget _buildLeagueHeader({
    required BuildContext context,
    required bool isDark,
    required LeagueTier currentTier,
    required LeagueTier? nextTier,
    required int userXp,
    required double tierProgress,
    required int xpNeeded,
    required String username,
    required String avatarId,
    required int? myRank,
    required bool isDistrictMode,
    required String districtName,
  }) {
    final numberFormat = NumberFormat.decimalPattern();
    final formattedXp = numberFormat.format(userXp);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? currentTier.primaryColor.withValues(alpha: 0.3)
              : currentTier.primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: currentTier.primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Subtle accent corner gradient (soft & rounded, not a sharp square)
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      currentTier.primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: League Shield Icon + League Title + Tier Badge
                  Row(
                    children: [
                      // Badge Icon with stylish background
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              currentTier.primaryColor,
                              currentTier.secondaryColor,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: currentTier.primaryColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          currentTier.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),

                      // League Name & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  currentTier.name,
                                  style: AppTextStyles.h2.copyWith(
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: currentTier.primaryColor.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Tier ${currentTier.tierLevel}',
                                    style: TextStyle(
                                      color: currentTier.primaryColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentTier.description,
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Row 2: Current User Card with Avatar, Name, Rank, and XP
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2B38) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        UserAvatar(
                          avatarId: avatarId,
                          username: username,
                          size: 38,
                          borderColor: AppColors.primaryGreen,
                          borderWidth: 2,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      username,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.18),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'You',
                                      style: TextStyle(
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                myRank != null 
                                    ? '#$myRank in ${isDistrictMode ? districtName : "Global"}'
                                    : 'Unranked in Top 30',
                                style: TextStyle(
                                  color: myRank != null ? AppColors.primaryGreen : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // User XP Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: currentTier.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: currentTier.primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 16,
                                color: currentTier.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$formattedXp XP',
                                style: TextStyle(
                                  color: currentTier.primaryColor,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Row 3: Progress Bar towards next League
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nextTier != null
                            ? '${numberFormat.format(xpNeeded)} XP to ${nextTier.name}'
                            : 'Maximum League Achieved! 🏆',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(tierProgress * 100).toInt()}%',
                        style: TextStyle(
                          color: currentTier.primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: tierProgress,
                      minHeight: 7,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(currentTier.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dedicated Streak Hero Header showing current user's streak and global status
  Widget _buildStreakHeader({
    required BuildContext context,
    required bool isDark,
    required int userStreak,
    required String username,
    required String avatarId,
    required int? myStreakRank,
  }) {
    const streakColor = Color(0xFFFF9600);
    const streakFlame = Color(0xFFFF5722);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E28) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: streakColor.withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: streakColor.withValues(alpha: isDark ? 0.08 : 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Streak Badge + Title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [streakColor, streakFlame],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: streakColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Streak Champions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: streakColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Top 10',
                            style: TextStyle(
                              color: streakColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Daily consistency leaders across all learners',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Row 2: User's Own Streak Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2836) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                UserAvatar(
                  avatarId: avatarId,
                  username: username,
                  size: 38,
                  borderColor: AppColors.primaryGreen,
                  borderWidth: 2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              username,
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(
                                color: AppColors.primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        myStreakRank != null
                            ? '#$myStreakRank in Global Streaks'
                            : 'Practice daily to enter Top 10!',
                        style: TextStyle(
                          color: myStreakRank != null ? streakColor : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: streakColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: streakColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: streakColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$userStreak ${userStreak == 1 ? "Day" : "Days"}',
                        style: const TextStyle(
                          color: streakColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
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
    );
  }
}

/// Category Tab Switcher (XP League vs Top Streaks)
class _CategoryTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF263242) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Filter tab item (District / Global)
class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2B3747) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                  : (isDark ? Colors.white54 : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card representing a contender in the Top 30
class _LeaderboardRankCard extends StatelessWidget {
  final int rank;
  final String username;
  final String? avatarId;
  final String? district;
  final int xp;
  final int? streak;
  final bool isStreakMode;
  final bool isMe;
  final bool isDark;
  final bool showDistrictBadge;

  const _LeaderboardRankCard({
    super.key,
    required this.rank,
    required this.username,
    required this.avatarId,
    required this.district,
    this.xp = 0,
    this.streak,
    this.isStreakMode = false,
    required this.isMe,
    required this.isDark,
    required this.showDistrictBadge,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern();
    final formattedXp = numberFormat.format(xp);

    // Podium ranks styling
    Color rankColor;
    Widget? rankBadge;

    if (rank == 1) {
      rankColor = const Color(0xFFFFB800); // Gold
      rankBadge = const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFB800), size: 24);
    } else if (rank == 2) {
      rankColor = const Color(0xFF94A3B8); // Silver
      rankBadge = const Icon(Icons.military_tech_rounded, color: Color(0xFF94A3B8), size: 24);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      rankBadge = const Icon(Icons.military_tech_rounded, color: Color(0xFFCD7F32), size: 24);
    } else {
      rankColor = isDark ? Colors.white54 : const Color(0xFF64748B);
    }

    final cardBg = isMe
        ? (isDark ? const Color(0xFF132822) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF161E28) : Colors.white);

    final borderColor = isMe
        ? AppColors.primaryGreen
        : (rank <= 3
            ? rankColor.withValues(alpha: isDark ? 0.35 : 0.25)
            : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)));

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: isMe ? 2 : (rank <= 3 ? 1.5 : 1),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          if (isMe)
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Rank Number or Medal
            SizedBox(
              width: 34,
              child: rankBadge ??
                  Text(
                    rank.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: rankColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
            ),

            const SizedBox(width: 8),

            // Contender Avatar
            UserAvatar(
              avatarId: avatarId,
              username: username,
              size: 42,
              borderColor: rank <= 3 ? rankColor : (isMe ? AppColors.primaryGreen : null),
              borderWidth: rank <= 3 || isMe ? 2 : 0,
            ),

            const SizedBox(width: 12),

            // Contender Name & District tag
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isMe ? '$username (You)' : username,
                          style: TextStyle(
                            color: isMe
                                ? AppColors.primaryGreen
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (showDistrictBadge && district != null && district!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      district!,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Badge (Streak or XP)
            if (isStreakMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E1A0E) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFF9600).withValues(alpha: isDark ? 0.4 : 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: Color(0xFFFF9600),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${streak ?? 0} ${(streak ?? 0) == 1 ? "Day" : "Days"}',
                      style: const TextStyle(
                        color: Color(0xFFFF9600),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.25) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                  ),
                ),
                child: Text(
                  '$formattedXp XP',
                  style: TextStyle(
                    color: isMe
                        ? AppColors.primaryGreen
                        : (rank == 1 ? const Color(0xFFFFB800) : (isDark ? Colors.white : const Color(0xFF0F172A))),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
