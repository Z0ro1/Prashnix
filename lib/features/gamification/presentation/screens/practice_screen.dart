import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.white54, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white.withValues(alpha: 0.1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4, )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber,
                              boxShadow: [
                                BoxShadow(color: AppColors.accentAmber.withValues(alpha: 0.5), blurRadius: 10)
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.accentRed, size: 24),
                      const SizedBox(width: 4),
                      const Text(
                        '5',
                        style: TextStyle(color: AppColors.accentRed, fontWeight: FontWeight.bold, fontSize: 18),
                      )
                    ],
                  )
                ],
              ),
            ),
            
            // Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Translate this sentence',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            
            // Character & Speech Bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Placeholder Character
                  Container(
                    width: 80,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMint.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.2), blurRadius: 20)
                      ],
                    ),
                    child: const Icon(Icons.person, size: 60, color: AppColors.primaryMint),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).slideY(begin: 0.05, end: -0.05, duration: 2.seconds),
                  const SizedBox(width: 16),
                  // Speech Bubble
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.volume_up, color: AppColors.skyBlue),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Amanda y yo\nhablamos con la maestra.',
                                  style: TextStyle(fontSize: 18, height: 1.5, color: Colors.white),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),

            // Drop Zone
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 2),
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildWordChip('We', true),
                  _buildWordChip('are', true),
                  _buildWordChip('men', true),
                ],
              ),
            ),

            const Spacer(),

            // Word Bank
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildWordChip('ten', false),
                  _buildEmptyChip(),
                  _buildWordChip('sorry', false),
                  _buildWordChip('four', false),
                  _buildEmptyChip(),
                  _buildEmptyChip(),
                  _buildWordChip('always', false),
                ],
              ),
            ),

            // Bottom Success Sheet
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: AppColors.featherGreen.withValues(alpha: 0.15),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.featherGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppColors.featherGreen.withValues(alpha: 0.5), blurRadius: 10)
                              ],
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Nice!',
                            style: TextStyle(
                              color: AppColors.featherGreen,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Icon(Icons.ios_share, color: AppColors.featherGreen.withValues(alpha: 0.8)),
                          const SizedBox(width: 16),
                          Icon(Icons.flag_outlined, color: AppColors.featherGreen.withValues(alpha: 0.8)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.featherGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.white24)),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(String text, bool isSelected) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            boxShadow: isSelected
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      offset: const Offset(0, 2),
                    )
                  ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChip() {
    return Container(
      width: 60,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
    );
  }
}
