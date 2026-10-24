import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../theme/prashnix_colors.dart';
import '../theme/prashnix_text_styles.dart';
import 'prashnix_audio_service.dart';

class PrashnixStatsBar extends StatelessWidget implements PreferredSizeWidget {
  final int streakDays;
  final int gems;
  final int hearts;
  final String languageFlag;
  final VoidCallback? onFlagTap;
  final VoidCallback? onStreakTap;
  final VoidCallback? onGemsTap;
  final VoidCallback? onHeartsTap;

  const PrashnixStatsBar({
    super.key,
    this.streakDays = 0,
    this.gems = 0,
    this.hearts = 5,
    this.languageFlag = '📍 Pune',
    this.onFlagTap,
    this.onStreakTap,
    this.onGemsTap,
    this.onHeartsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  Widget _buildFlagPill(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        PrashnixAudioService.playTap();
        onFlagTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDimDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : PrashnixColors.border, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languageFlag,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : PrashnixColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: isDark ? AppColors.textMutedDark : PrashnixColors.textSecondary, size: 18),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barBg = isDark ? AppColors.surfaceDark : Colors.white;
    final borderCol = isDark ? AppColors.borderDark : PrashnixColors.border;

    return Container(
      color: barBg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: barBg,
            border: Border(
              bottom: BorderSide(color: borderCol, width: 2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildFlagPill(context, isDark),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatItem(
                    icon: const Text('🔥', style: TextStyle(fontSize: 18)),
                    value: '$streakDays',
                    textStyle: PrashnixTextStyles.statStreak,
                    onTap: onStreakTap ?? () => PrashnixAudioService.playStreakFlame(),
                  ),
                  const SizedBox(width: 14),
                  _buildStatItem(
                    icon: const Text('💎', style: TextStyle(fontSize: 18)),
                    value: '$gems',
                    textStyle: PrashnixTextStyles.statGems,
                    onTap: onGemsTap ?? () => PrashnixAudioService.playGemsReward(),
                  ),
                  const SizedBox(width: 14),
                  _buildStatItem(
                    icon: const Text('❤️', style: TextStyle(fontSize: 18)),
                    value: '$hearts',
                    textStyle: PrashnixTextStyles.statHearts,
                    onTap: onHeartsTap ?? () => PrashnixAudioService.playTap(),
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
