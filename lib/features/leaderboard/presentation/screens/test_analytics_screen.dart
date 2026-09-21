import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../gamification/presentation/providers/heart_economy_provider.dart';
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
    final heartNotifier = ref.read(heartEconomyProvider.notifier);
    heartNotifier.addXp(500);
    // Fill to 25 (if they had 0, add 25)
    final currentHearts = ref.read(heartEconomyProvider).heartCount;
    if (currentHearts < 25) {
      heartNotifier.addHearts(25 - currentHearts);
    }

    // 2. Cloud Sync
    final state = ref.read(heartEconomyProvider);
    final syncRepo = CloudSyncRepository();
    await syncRepo.syncProgressToCloud(
      xp: state.totalXp,
      streak: state.streakCount,
      hearts: state.heartCount,
    );

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timedExamNotifierProvider);
    final correct = state.correctCount;
    final total = state.questions.length;
    final answered = state.answeredCount;
    
    // Standard mock scoring: 1 mark for correct, -0.25 for incorrect
    final incorrect = answered - correct;
    final score = correct - (incorrect * 0.25);
    final accuracy = answered > 0 ? (correct / answered * 100).round() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing Score & Syncing to Cloud...'),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: Text('🏆', style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Exam Submitted!',
                      style: AppTextStyles.h1,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    // Score Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                        ],
                      ),
                      child: Column(
                        children: [
                          Text('Final Score', style: AppTextStyles.label.copyWith(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            score.toStringAsFixed(2),
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text('out of $total', style: AppTextStyles.label.copyWith(color: Colors.white70)),
                          const Divider(height: 32, color: Colors.white24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(label: 'Accuracy', value: '$accuracy%'),
                              _StatItem(label: 'Attempted', value: '$answered'),
                              _StatItem(label: 'Correct', value: '$correct', valueColor: AppColors.success),
                              _StatItem(label: 'Incorrect', value: '$incorrect', valueColor: AppColors.error),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    Text('Rewards Unlocked', style: AppTextStyles.h3),
                    const SizedBox(height: 16),

                    // Rewards
                    Row(
                      children: [
                        Expanded(
                          child: _RewardCard(
                            icon: '💎',
                            title: '+500 XP',
                            subtitle: 'Weekly boost applied',
                            color: const Color(0xFFE3F2FD),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RewardCard(
                            icon: '❤️',
                            title: 'Full Reset',
                            subtitle: 'Hearts maxed to 25',
                            color: const Color(0xFFFFEBEE),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    CustomButton(
                      text: 'View Leaderboard Standings',
                      backgroundColor: AppColors.primary,
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
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
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
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
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
          Text(subtitle, style: AppTextStyles.label),
        ],
      ),
    );
  }
}
