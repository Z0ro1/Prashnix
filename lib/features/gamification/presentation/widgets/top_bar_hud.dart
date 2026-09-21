import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/state/user_state.dart';

class TopBarHUD extends ConsumerWidget implements PreferredSizeWidget {
  const TopBarHUD({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userStoreProvider);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.surfaceLight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Course/Language (Flag placeholder)
            _buildStatChip(
              icon: Icons.flag_rounded,
              value: '14',
              color: Colors.blueGrey,
            ),
            
            // Streak counter
            _buildStatChip(
              icon: Icons.local_fire_department_rounded,
              value: state.streakCount.toString(),
              color: AppColors.accentAmber,
            ),

            // Gems
            _buildStatChip(
              icon: Icons.diamond_rounded,
              value: '527', // Placeholder for gems
              color: const Color(0xFF00BFFF), // Blue
            ),
            
            // Heart counter
            _buildStatChip(
              icon: Icons.favorite_rounded,
              value: state.heartCount.toString(),
              color: AppColors.accentRed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 6),
            Text(
              value,
              style: AppTextStyles.label.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
