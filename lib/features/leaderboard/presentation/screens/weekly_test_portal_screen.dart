import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import 'timed_exam_screen.dart';

class WeeklyTestPortalScreen extends ConsumerWidget {
  const WeeklyTestPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.5),
                  radius: 1.0,
                  colors: [
                    AppColors.canaryYellow.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          Column(
            children: [
              // Neon Hero Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 100, 24, 48),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  border: Border(bottom: BorderSide(color: AppColors.canaryYellow.withValues(alpha: 0.2))),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.canaryYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.canaryYellow.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(color: AppColors.canaryYellow.withValues(alpha: 0.2), blurRadius: 10),
                        ]
                      ),
                      child: Text(
                        'PUNE DISTRICT CHAMPIONSHIP TEST',
                        style: AppTextStyles.label.copyWith(color: AppColors.canaryYellow, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white54),
                    const SizedBox(height: 24),
                    Text(
                      'Weekly 100-Mark Mock',
                      style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32),
                      textAlign: TextAlign.center,
                    ).animate().fade().slideY(begin: 0.2),
                    const SizedBox(height: 16),
                    Text(
                      'Assess your readiness against thousands of candidates in your district.',
                      style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                      textAlign: TextAlign.center,
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Exam Specs Glass Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SpecItem(icon: Icons.list_alt_rounded, value: '100', label: 'Questions'),
                                Container(width: 1, height: 40, color: Colors.white24),
                                _SpecItem(icon: Icons.timer_rounded, value: '90', label: 'Minutes'),
                                Container(width: 1, height: 40, color: Colors.white24),
                                _SpecItem(icon: Icons.warning_amber_rounded, value: '-0.25', label: 'Negative'),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 400.ms).slideY(begin: 0.2),
                      const SizedBox(height: 24),
                      
                      // Reward Preview Glass Banner
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.canaryYellow.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.canaryYellow.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Completion Rewards',
                                  style: AppTextStyles.h3.copyWith(color: AppColors.canaryYellow),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('💎 +500 XP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                    const SizedBox(width: 16),
                                    const Text('❤️ Full Reset', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fade(delay: 600.ms).slideY(begin: 0.2),
                      
                      const SizedBox(height: 48),
                      
                      // Start Action
                      CustomButton(
                        text: 'Start Official Mock Test',
                        variant: ButtonVariant.primaryMint,
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => const TimedExamScreen()),
                          );
                        },
                      ).animate().fade(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),
                    ],
                  ),
                ),
              ),
            ],
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
        Icon(icon, color: AppColors.primaryMint),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(color: Colors.white54)),
      ],
    );
  }
}
