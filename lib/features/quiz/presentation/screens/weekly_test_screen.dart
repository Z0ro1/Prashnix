import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';

class WeeklyTestScreen extends ConsumerStatefulWidget {
  const WeeklyTestScreen({super.key});

  @override
  ConsumerState<WeeklyTestScreen> createState() => _WeeklyTestScreenState();
}

class _WeeklyTestScreenState extends ConsumerState<WeeklyTestScreen> {
  late Timer _timer;
  Duration _timeLeft = const Duration();

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    // Next Sunday 12:00 PM
    var nextSunday = now.add(Duration(days: DateTime.sunday - now.weekday));
    nextSunday = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 12, 0, 0);
    
    if (now.isAfter(nextSunday)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }
    
    if (mounted) {
      setState(() {
        _timeLeft = nextSunday.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String days = d.inDays.toString();
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
              decoration: const BoxDecoration(
                color: Color(0xFF1A237E), // Deep Navy
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'WEEKLY CHAMPIONSHIP TEST',
                      style: AppTextStyles.label.copyWith(color: Colors.white, letterSpacing: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Next Test Closes In:',
                    style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '⏳ ${_formatDuration(_timeLeft)}',
                    style: AppTextStyles.h1.copyWith(color: AppColors.canaryYellow, fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // High Score Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Text('Last Week', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('85/100', style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                          ],
                        ),
                        Container(width: 1, height: 40, color: AppColors.surfaceLight),
                        Column(
                          children: [
                            Text('All-Time Best', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('92/100', style: AppTextStyles.h2.copyWith(color: AppColors.primaryMint)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Leaderboard Teaser
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade100, Colors.blue.shade100],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text('👑', style: TextStyle(fontSize: 32)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Leader: Rahul', style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
                              Text('Score: 98/100. Can you beat him?', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Rules & Specs
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SpecItem(icon: Icons.list_alt, value: '100', label: 'Questions'),
                        Container(width: 1, height: 40, color: AppColors.surfaceLight),
                        _SpecItem(icon: Icons.timer, value: '90', label: 'Minutes'),
                        Container(width: 1, height: 40, color: AppColors.surfaceLight),
                        _SpecItem(icon: Icons.warning_amber_rounded, value: '-0.25', label: 'Negative'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Reward Preview
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1), // Soft Gold
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Completion Rewards',
                          style: AppTextStyles.h3.copyWith(color: const Color(0xFFF57F17)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('💎 +500 XP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 16),
                            const Text('❤️ Full Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  CustomButton(
                    text: 'START OFFICIAL MOCK TEST',
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      ref.read(quizProvider.notifier).loadQuestionsForNode('weekly_test');
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const QuizScreen()),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _SpecItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary)),
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
