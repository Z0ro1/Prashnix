import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
import '../../../../core/state/user_state.dart';
import '../../data/repositories/cloud_sync_repository.dart';
import '../providers/timed_exam_provider.dart';
import 'leaderboard_screen.dart';

class TestAnalyticsScreen extends ConsumerStatefulWidget {
  const TestAnalyticsScreen({super.key});

  @override
  ConsumerState<TestAnalyticsScreen> createState() => _TestAnalyticsScreenState();
}

class _TestAnalyticsScreenState extends ConsumerState<TestAnalyticsScreen> {
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _processRewardsAndSync();
  }

  Future<void> _processRewardsAndSync() async {
    // 1. Reset Hearts & Give 500 XP
    final userNotifier = ref.read(userStoreProvider.notifier);
    userNotifier.addXp(500);
    // Fill to 25 (if they had 0, add 25)
    final currentHearts = ref.read(userStoreProvider).heartCount;
    if (currentHearts < 25) {
      ref.read(heartEconomyProvider.notifier).addHearts(25 - currentHearts);
    }

    // 2. Cloud Sync
    final user = ref.read(userStoreProvider);
    final syncRepo = CloudSyncRepository();
    await syncRepo.syncProgressToCloud(
      xp: user.totalXp,
      streak: user.streakCount,
      hearts: user.heartCount,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timedExamProvider);
    final correct = state.correctCount;
    final total = state.questions.length;
    final answered = state.answeredCount;
    
    // Standard mock scoring: 1 mark for correct, -0.25 for incorrect
    final incorrect = answered - correct;
    final score = correct - (incorrect * 0.25);
    final accuracy = answered > 0 ? (correct / answered * 100).round() : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: 100,
            left: -50,
            right: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryMint.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: _isProcessing
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primaryMint),
                        const SizedBox(height: 24),
                        Text(
                          'Analyzing Score & Syncing to Cloud...',
                          style: AppTextStyles.body.copyWith(color: AppColors.primaryMint),
                        ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1500.ms, color: Colors.white),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 80)),
                        ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                        const SizedBox(height: 16),
                        Text(
                          'Exam Submitted!',
                          style: AppTextStyles.h1.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                        const SizedBox(height: 32),
                        
                        // Score Card
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Column(
                                children: [
                                  Text('Final Score', style: AppTextStyles.label.copyWith(color: Colors.white70)),
                                  const SizedBox(height: 8),
                                  Text(
                                    score.toStringAsFixed(2),
                                    style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: AppColors.canaryYellow),
                                  ).animate().fade(delay: 600.ms).scale(curve: Curves.easeOutBack),
                                  Text('out of $total', style: AppTextStyles.label.copyWith(color: Colors.white54)),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Divider(height: 1, color: Colors.white24),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _StatItem(label: 'Accuracy', value: '$accuracy%'),
                                      _StatItem(label: 'Attempted', value: '$answered'),
                                      _StatItem(label: 'Correct', value: '$correct', valueColor: AppColors.primaryMint),
                                      _StatItem(label: 'Incorrect', value: '$incorrect', valueColor: AppColors.accentRed),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
    
                        const SizedBox(height: 48),
                        Text('Rewards Unlocked', style: AppTextStyles.h3.copyWith(color: Colors.white)).animate().fade(delay: 800.ms),
                        const SizedBox(height: 16),
    
                        // Rewards
                        Row(
                          children: [
                            Expanded(
                              child: _RewardCard(
                                icon: '💎',
                                title: '+500 XP',
                                subtitle: 'Weekly boost applied',
                                color: AppColors.canaryYellow,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _RewardCard(
                                icon: '❤️',
                                title: 'Full Reset',
                                subtitle: 'Hearts maxed to 25',
                                color: AppColors.accentRed,
                              ),
                            ),
                          ],
                        ).animate().fade(delay: 900.ms).slideY(begin: 0.1),
    
                        const SizedBox(height: 48),
    
                        CustomButton(
                          text: 'View Leaderboard Standings',
                          variant: ButtonVariant.primaryMint,
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                            );
                          },
                        ).animate().fade(delay: 1000.ms).slideY(begin: 0.2),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatItem({required this.label, required this.value, this.valueColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valueColor)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white70)),
      ],
    );
  }
}

class _RewardCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;

  const _RewardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18, color: color)),
          Text(subtitle, style: AppTextStyles.label.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}
