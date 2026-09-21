import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MistakeReviewScreen extends StatelessWidget {
  const MistakeReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocked mistake data
    final mistakes = [
      {'question': 'मराठी भाषेत एकूण किती वर्ण मानले जातात?', 'wrongAnswer': '48', 'correctAnswer': '52'},
      {'question': 'कोणत्या जिल्ह्याला साखरेचा जिल्हा म्हणतात?', 'wrongAnswer': 'सोलापूर', 'correctAnswer': 'अहमदनगर'},
      {'question': 'भारताचे पहिले पंतप्रधान कोण होते?', 'wrongAnswer': 'महात्मा गांधी', 'correctAnswer': 'पंडित नेहरू'},
    ];

    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Mistake Review', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mistakes.length,
        itemBuilder: (context, index) {
          final m = mistakes[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m['question']!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnswerRow(m['wrongAnswer']!, isCorrect: false),
                const SizedBox(height: 8),
                _buildAnswerRow(m['correctAnswer']!, isCorrect: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnswerRow(String text, {required bool isCorrect}) {
    final color = isCorrect ? AppColors.primaryMint : AppColors.error;
    final icon = isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded;
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
