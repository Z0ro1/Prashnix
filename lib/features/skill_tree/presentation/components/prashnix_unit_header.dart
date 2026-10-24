import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/prashnix_colors.dart';
import '../theme/prashnix_text_styles.dart';
import 'prashnix_audio_service.dart';

class PrashnixUnitHeader extends StatelessWidget {
  final int unitNumber;
  final String title;
  final String description;
  final Color? color;
  final VoidCallback? onGuidebookTap;

  const PrashnixUnitHeader({
    super.key,
    this.unitNumber = 1,
    this.title = 'MPSC Foundation & Basics',
    this.description = 'Learn essential syllabus concepts, scoring patterns, and core notes.',
    this.color,
    this.onGuidebookTap,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = color ?? PrashnixColors.green;
    final bevelColor = color != null 
        ? HSLColor.fromColor(color!).withLightness((HSLColor.fromColor(color!).lightness - 0.15).clamp(0.0, 1.0)).toColor()
        : PrashnixColors.greenDarkBevel;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: bevelColor,
            offset: const Offset(0, 4),
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
                    style: PrashnixTextStyles.unitTag,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: PrashnixTextStyles.unitTitle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: PrashnixTextStyles.unitSubtext,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Guidebook Action Button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                PrashnixAudioService.playTap();
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
