import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/state/user_state.dart';
import 'package:go_router/go_router.dart';

class TopBarHUD extends ConsumerWidget implements PreferredSizeWidget {
  const TopBarHUD({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userStoreProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Streak counter
            _buildStatChip(
              icon: '🔥',
              value: state.streakCount.toString(),
              color: AppColors.stepOrange,
            ),
            
            // Heart counter
            _buildStatChip(
              icon: '❤️',
              value: state.heartCount.toString(),
              color: AppColors.error,
              onTap: () {
                context.push('/hearts');
              },
            ),

            // XP / Level
            _buildStatChip(
              icon: '💎',
              value: state.totalXp.toString(),
              color: AppColors.waterBlue,
            ),
            
            // Avatar profile button
            GestureDetector(
              onTap: () {
                // Navigate to profile
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryGreen, width: 2),
                  image: DecorationImage(
                    image: AssetImage(state.avatarId.isNotEmpty 
                        ? 'assets/avatars/${state.avatarId}' 
                        : 'assets/avatars/luffy.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required String icon,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTypography.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
