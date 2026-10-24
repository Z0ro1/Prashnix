import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'duo_audio_service.dart';

class DuoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DuoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;
    final Color color = isSelected ? AppColors.green : AppColors.textMuted;
    final TextStyle textStyle = isSelected ? AppTextStyles.navItemActive : AppTextStyles.navItemInactive;

    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          DuoAudioService.playTap();
          onTap(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 4),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.school_rounded,
                label: 'LEARN',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.shield_rounded,
                label: 'LEAGUES',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.person_rounded,
                label: 'PROFILE',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
