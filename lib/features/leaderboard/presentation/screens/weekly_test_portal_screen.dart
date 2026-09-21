import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import 'timed_exam_screen.dart';

class WeeklyTestPortalScreen extends ConsumerWidget {
  const WeeklyTestPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In a real app, you'd check if today is Sunday, but the user requested it to be an option available anytime for testing/convenience.

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Column(
        children: [
          // Deep Navy Hero Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 48),
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
                    'PUNE DISTRICT CHAMPIONSHIP TEST',
                    style: AppTextStyles.label.copyWith(color: Colors.white, letterSpacing: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Weekly 100-Mark Mock',
                  style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Assess your readiness against thousands of candidates in your district.',
                  style: AppTextStyles.body.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Exam Specs Card
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
                  
                  // Reward Preview Banner
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
                  
                  const SizedBox(height: 48),
                  
                  // Start Action
                  CustomButton(
                    text: 'Start Official Mock Test',
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => const TimedExamScreen()),
                      );
                    },
                  ),
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
