import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class QuizProgressBar extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;

  const QuizProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    // We add 1 because currentIndex is 0-based. So 0/25 -> 1/25 fill initially (or 0 if you want)
    // Actually, filling it as you complete makes sense. If currentIndex == 0, progress = 0.
    // If you want it to show current step, (currentIndex + 1) / totalQuestions is good.
    final progress = (currentIndex) / totalQuestions; 
    
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: constraints.maxWidth * progress,
                decoration: BoxDecoration(
                  color: AppColors.success, // User explicitly asked to keep it green
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
