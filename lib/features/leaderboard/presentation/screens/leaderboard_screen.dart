import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardNotifierProvider);
    final notifier = ref.read(leaderboardNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Leaderboard', style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Toggles
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _ModeToggle(
                    title: 'My District',
                    isActive: state.isDistrictMode,
                    onTap: () => notifier.toggleMode(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ModeToggle(
                    title: 'State',
                    isActive: !state.isDistrictMode,
                    onTap: () => notifier.toggleMode(false),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: notifier.refresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (state.ranks.length >= 3)
                          SliverToBoxAdapter(
                            child: _buildPodium(state.ranks.sublist(0, 3)),
                          ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final rankIndex = index + 3;
                              if (rankIndex >= state.ranks.length) return null;
                              final candidate = state.ranks[rankIndex];
                              return _LeaderboardRow(
                                rank: rankIndex + 1,
                                candidate: candidate,
                              );
                            },
                            childCount: state.ranks.length > 3 ? state.ranks.length - 3 : 0,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: state.isLoading || state.ranks.isEmpty
          ? null
          : _StickyActiveUserBar(rank: 14, candidate: state.ranks.first), // Mocking active user for now
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PodiumColumn(rank: 2, candidate: top3[1], height: 120, color: const Color(0xFFC0C0C0)),
          const SizedBox(width: 8),
          _PodiumColumn(rank: 1, candidate: top3[0], height: 160, color: const Color(0xFFFFB800), isFirst: true),
          const SizedBox(width: 8),
          _PodiumColumn(rank: 3, candidate: top3[2], height: 100, color: const Color(0xFFCD7F32)),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeToggle({required this.title, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? AppColors.primary : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyles.label.copyWith(
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> candidate;
  final double height;
  final Color color;
  final bool isFirst;

  const _PodiumColumn({
    required this.rank,
    required this.candidate,
    required this.height,
    required this.color,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) const Text('👑', style: TextStyle(fontSize: 32)),
        CircleAvatar(
          radius: isFirst ? 36 : 28,
          backgroundImage: AssetImage(candidate['avatar_id'] ?? 'assets/avatars/default.jpg'),
          backgroundColor: AppColors.surfaceLight,
        ),
        const SizedBox(height: 8),
        Text(
          candidate['username'] ?? 'User',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        Text('${candidate['weekly_xp']} XP', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.5),
                blurRadius: 10,
                offset: const Offset(0, -2),
              )
            ],
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '$rank',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> candidate;

  const _LeaderboardRow({required this.rank, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(candidate['avatar_id'] ?? 'assets/avatars/default.jpg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              candidate['username'] ?? 'Unknown',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '${candidate['weekly_xp']} XP',
            style: AppTextStyles.label.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StickyActiveUserBar extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> candidate;

  const _StickyActiveUserBar({required this.rank, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          border: const Border(top: BorderSide(color: AppColors.primary, width: 2)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '$rank',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(candidate['avatar_id'] ?? 'assets/avatars/default.jpg'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You',
                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text(
                    '120 XP to Top 10',
                    style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '${candidate['weekly_xp']} XP',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
