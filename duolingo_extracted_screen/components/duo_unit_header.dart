import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'duo_audio_service.dart';

class DuoUnitHeader extends StatelessWidget {
  final int unitNumber;
  final String title;
  final String description;
  final VoidCallback? onGuidebookTap;

  const DuoUnitHeader({
    super.key,
    this.unitNumber = 1,
    this.title = 'Order Food & Drinks',
    this.description = 'Learn basic café vocabulary, greetings, and ordering essentials.',
    this.onGuidebookTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.greenDarkBevel,
            offset: Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIT $unitNumber',
                    style: AppTextStyles.unitTag,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: AppTextStyles.unitTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: AppTextStyles.unitSubtext,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Guidebook Action Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                DuoAudioService.playTap();
                onGuidebookTap?.call();
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
