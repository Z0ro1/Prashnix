import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../features/profile/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/user_state.dart';
import '../../features/skill_tree/data/repositories/sync_service.dart';
import '../../features/skill_tree/presentation/providers/skill_tree_provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      await ref.read(userStoreProvider.notifier).refreshProfile();
      // Sync progress from cloud to SQLite
      await SyncService().pullProgress();
      // Refresh the skill tree state so it loads the newly downloaded progress
      ref.invalidate(skillTreeProvider);
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      extendBody: true, // Crucial for floating nav bar
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavItem(CupertinoIcons.home, 'Home', 0, context),
                      _buildNavItem(CupertinoIcons.doc_text, 'Review', 1, context),
                      _buildNavItem(CupertinoIcons.bell, 'Tests', 2, context),
                      _buildNavItem(CupertinoIcons.flame, 'Streaks', 3, context),
                      _buildNavItem(CupertinoIcons.person, 'Profile', 4, context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconData, String label, int index, BuildContext context) {
    final isSelected = widget.navigationShell.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final color = isSelected 
        ? AppColors.primaryGreenDark 
        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);

    return GestureDetector(
      onTap: () {
        if (index != widget.navigationShell.currentIndex) {
          if (ref.read(settingsProvider).hapticsEnabled) {
            HapticFeedback.selectionClick();
          }
        }
        widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Tooltip(
        message: label,
        preferBelow: false,
        verticalOffset: 24,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Removed Morphing Glass Bubble Background
                 
              // Icon
              Icon(iconData, size: 26, color: color)
                .animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 200.ms, curve: Curves.easeOutBack),
            ],
          ),
        ),
      ),
    );
  }
}
