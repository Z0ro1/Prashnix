import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/leaderboard_provider.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaderboardProvider);
    final notifier = ref.read(leaderboardProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Leaderboard', style: AppTextStyles.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: 100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 300,
              height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.foxOrange.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Toggles (Glassmorphism Pill)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeToggle(
                            title: 'My District',
                            isActive: state.isDistrictMode,
                            onTap: () => notifier.toggleMode(true),
                          ),
                        ),
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
                ).animate().fade().slideY(begin: -0.2),

                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryMint))
                      : RefreshIndicator(
                          color: AppColors.primaryMint,
                          backgroundColor: const Color(0xFF1A1D24),
                          onRefresh: notifier.refresh,
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            slivers: [
                              if (state.ranks.length >= 3)
                                SliverToBoxAdapter(
                                  child: _buildPodium(state.ranks.sublist(0, 3)),
                                ),
                              SliverPadding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final rankIndex = index + 3;
                                      if (rankIndex >= state.ranks.length) return null;
                                      final candidate = state.ranks[rankIndex];
                                      return _LeaderboardRow(
                                        rank: rankIndex + 1,
                                        candidate: candidate,
                                      ).animate().fade(delay: (50 * index).ms).slideX(begin: 0.1);
                                    },
                                    childCount: state.ranks.length > 3 ? state.ranks.length - 3 : 0,
                                  ),
                                ),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for sticky bar
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // Sticky User Bar
          if (!state.isLoading && state.ranks.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _StickyActiveUserBar(rank: 14, candidate: state.ranks.first).animate().slideY(begin: 1.0, curve: Curves.easeOutBack, duration: 600.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<Map<String, dynamic>> top3) {
    return Padding(
      padding: const EdgeInsets.only(top: 32, bottom: 16, left: 16, right: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PodiumColumn(rank: 2, candidate: top3[1], height: 120, color: const Color(0xFFC0C0C0), delay: 200),
          const SizedBox(width: 12),
          _PodiumColumn(rank: 1, candidate: top3[0], height: 160, color: AppColors.canaryYellow, isFirst: true, delay: 400),
          const SizedBox(width: 12),
          _PodiumColumn(rank: 3, candidate: top3[2], height: 100, color: const Color(0xFFCD7F32), delay: 0),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryMint : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isActive ? [
            BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.3), blurRadius: 10)
          ] : [],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyles.label.copyWith(
            color: isActive ? AppColors.deepTealNavy : Colors.white54,
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
  final int delay;

  const _PodiumColumn({
    required this.rank,
    required this.candidate,
    required this.height,
    required this.color,
    this.isFirst = false,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFirst) 
          const Text('👑', style: TextStyle(fontSize: 32))
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2.seconds, delay: delay.ms),
        
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 15)
            ],
          ),
          child: CircleAvatar(
            radius: isFirst ? 36 : 28,
            backgroundColor: const Color(0xFF1A1D24),
            // Default avatar if none provided
            child: Icon(Icons.person_rounded, size: isFirst ? 36 : 28, color: Colors.white54),
          ),
        ).animate().scale(delay: delay.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 12),
        Text(
          candidate['username'] ?? 'None',
          style: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
          overflow: TextOverflow.ellipsis,
        ).animate().fade(delay: (delay + 100).ms),
        
        Text(
          '${candidate['weekly_xp'] ?? 0} XP', 
          style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.bold)
        ).animate().fade(delay: (delay + 200).ms),
        
        const SizedBox(height: 12),
        
        // 3D Podium Block
        Container(
          width: 80,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.8),
                color.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: color, width: 2),
              left: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
              right: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
            ),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '$rank',
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              shadows: [Shadow(color: color, blurRadius: 20)],
            ),
          ),
        ).animate().slideY(begin: 1.0, duration: 600.ms, delay: delay.ms, curve: Curves.easeOutCubic),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '$rank',
                    style: AppTextStyles.h2.copyWith(color: Colors.white54, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF1A1D24),
                  child: Icon(Icons.person_rounded, color: Colors.white30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    candidate['username'] ?? 'None',
                    style: AppTextStyles.h3.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.foxOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.foxOrange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${candidate['weekly_xp'] ?? 0} XP',
                    style: AppTextStyles.label.copyWith(color: AppColors.foxOrange, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
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
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            left: 24, 
            right: 24, 
            top: 20, 
            bottom: MediaQuery.of(context).padding.bottom + 20
          ),
          decoration: BoxDecoration(
            color: AppColors.primaryMint.withValues(alpha: 0.1),
            border: const Border(top: BorderSide(color: AppColors.primaryMint, width: 2)),
            boxShadow: [
              BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, -5))
            ]
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '$rank',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryMint, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMint,
                ),
                child: const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF1A1D24),
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: AppTextStyles.h3.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      '${120} XP to Top 10', // Fake calculated logic placeholder
                      style: AppTextStyles.label.copyWith(color: AppColors.primaryMint),
                    ),
                  ],
                ),
              ),
              Text(
                '${candidate['weekly_xp'] ?? 0} XP',
                style: AppTextStyles.h2.copyWith(color: AppColors.primaryMint, fontWeight: FontWeight.bold),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
            ],
          ),
        ),
      ),
    );
  }
}
