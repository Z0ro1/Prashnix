import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Preferences', textColor),
              _buildSwitchTile(
                'Sound Effects', 
                Icons.volume_up_rounded, 
                settings.soundEnabled, 
                (val) => notifier.toggleSound(val), 
                textColor,
                isDark,
              ),
              _buildSwitchTile(
                'Haptic Feedback', 
                Icons.vibration_rounded, 
                settings.hapticsEnabled, 
                (val) => notifier.toggleHaptics(val), 
                textColor,
                isDark,
              ),
              _buildSwitchTile(
                'Dark Mode', 
                Icons.dark_mode_rounded, 
                settings.darkMode, 
                (val) => notifier.toggleDarkMode(val), 
                textColor,
                isDark,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Notifications', textColor),
              _buildSwitchTile(
                'Daily Reminders', 
                Icons.notifications_active_rounded, 
                settings.notificationsEnabled, 
                (val) => notifier.toggleNotifications(val), 
                textColor,
                isDark,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Support', textColor),
              _buildListTile('Report a Bug / Feedback', Icons.bug_report_rounded, textColor, isDark, onTap: () {}),
              _buildListTile('Help Center', Icons.help_outline_rounded, textColor, isDark, onTap: () {}),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Account', textColor),
              _buildListTile('Log Out', Icons.logout_rounded, AppColors.foxOrange, isDark, onTap: () {}),
              _buildListTile('Delete Account', Icons.delete_forever_rounded, AppColors.error, isDark, onTap: () {
                _showDeleteAccountDialog(context);
              }),

              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.skyBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Powered by Crexst Technologies',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.subtextCaption.copyWith(
          color: color.withValues(alpha: 0.6),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged, Color textColor, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: Icon(icon, color: AppColors.skyBlue),
      title: Text(title, style: AppTypography.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.featherGreen,
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, Color contentColor, bool isDark, {required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      leading: Icon(icon, color: contentColor),
      title: Text(title, style: AppTypography.bodyMedium.copyWith(color: contentColor, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text('Are you sure you want to delete your account? This action cannot be undone and you will lose all your progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested.')),
              );
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
