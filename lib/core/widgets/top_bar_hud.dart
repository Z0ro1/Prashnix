import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../constants/app_constants.dart';

class TopBarHUD extends ConsumerWidget {
  const TopBarHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userStoreProvider);

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Streak Pill
                _buildPill(
                  icon: '🔥',
                  text: userState.streakCount.toString(),
                  color: AppColors.accentAmber,
                ),
                
                // Heart Pill
                _buildPill(
                  icon: '❤️',
                  text: '${userState.heartCount}/5',
                  color: AppColors.accentRed,
                ),
    
                // Profile Avatar
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryMint,
                      width: 2.5,
                    ),
                    color: AppColors.deepTealNavy,
                    image: userState.avatarId.isNotEmpty
                        ? DecorationImage(
                            image: AssetImage('assets/avatars/${userState.avatarId}'),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: userState.avatarId.isEmpty
                      ? Center(
                          child: Text(
                            userState.username.isNotEmpty
                                ? userState.username[0].toUpperCase()
                                : 'G',
                            style: AppTypography.titleSemiBold.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill({required String icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
