import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                children: [
                  Icon(Icons.close, color: Colors.grey.shade400, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentAmber),
                        minHeight: 16,
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
                  color: AppColors.textPrimary,
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
                      color: AppColors.primaryMint.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.person, size: 60, color: AppColors.primaryMint),
                  ),
                  const SizedBox(width: 16),
                  // Speech Bubble
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.volume_up, color: Colors.blue.shade400),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Amanda y yo\nhablamos con la maestra.',
                              style: TextStyle(fontSize: 18, height: 1.5),
                            ),
                          )
                        ],
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
                  top: BorderSide(color: Colors.grey.shade300, width: 2),
                  bottom: BorderSide(color: Colors.grey.shade300, width: 2),
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
            Container(
              color: const Color(0xFFD7FFB8),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF58CC02), size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Nice!',
                        style: TextStyle(
                          color: Color(0xFF58CC02),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.ios_share, color: const Color(0xFF58CC02).withOpacity(0.8)),
                      const SizedBox(width: 16),
                      Icon(Icons.flag_outlined, color: const Color(0xFF58CC02).withOpacity(0.8)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF58CC02),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
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
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: isSelected
            ? []
            : [
                BoxShadow(
                  color: Colors.grey.shade300,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEmptyChip() {
    return Container(
      width: 60,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
