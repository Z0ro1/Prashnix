import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'duo_audio_service.dart';

class DuoStatsBar extends StatelessWidget implements PreferredSizeWidget {
  final int streakDays;
  final int gems;
  final int hearts;
  final String languageFlag;
  final VoidCallback? onFlagTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onGemsTap;
  final VoidCallback? onHeartsTap;

  const DuoStatsBar({
    super.key,
    this.streakDays = 16,
    this.gems = 565,
    this.hearts = 5,
    this.languageFlag = '🇪🇸',
    this.onFlagTap,
    this.onStreakTap,
    this.onGemsTap,
    this.onHeartsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  Widget _buildFlagPill(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        DuoAudioService.playTap();
        onFlagTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(languageFlag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required Widget icon,
    required String value,
    required TextStyle textStyle,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(value, style: textStyle),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlagPill(context),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    icon: const Text('🔥', style: TextStyle(fontSize: 18)),
                    value: '$streakDays',
                    textStyle: AppTextStyles.statStreak,
                    onTap: onStreakTap ?? () => DuoAudioService.playStreakFlame(),
                  ),
                  const SizedBox(width: 14),
                  _buildStatItem(
                    icon: const Text('💎', style: TextStyle(fontSize: 18)),
                    value: '$gems',
                    textStyle: AppTextStyles.statGems,
                    onTap: onGemsTap ?? () => DuoAudioService.playGemsReward(),
                  ),
                  const SizedBox(width: 14),
                  _buildStatItem(
                    icon: const Text('❤️', style: TextStyle(fontSize: 18)),
                    value: '$hearts',
                    textStyle: AppTextStyles.statHearts,
                    onTap: onHeartsTap ?? () => DuoAudioService.playTap(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
