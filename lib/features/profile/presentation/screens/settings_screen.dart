import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/settings_provider.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/progress_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.headlineMedium.copyWith(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Preferences', context).animate().fade().slideX(),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                children: [
                  _buildSwitchTile(
                    'Dark Mode', 
                    Icons.dark_mode_rounded, 
                    settings.darkMode, 
                    (val) => notifier.toggleDarkMode(val),
                    context,
                  ),
                  _buildDivider(context),
                  _buildSwitchTile(
                    'Sound Effects', 
                    Icons.volume_up_rounded, 
                    settings.soundEnabled, 
                    (val) => notifier.toggleSound(val),
                    context,
                  ),
                  _buildDivider(context),
                  _buildSwitchTile(
                    'Haptic Feedback', 
                    Icons.vibration_rounded, 
                    settings.hapticsEnabled, 
                    (val) => notifier.toggleHaptics(val),
                    context,
                  ),
                ],
              ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 32),
              
              _buildSectionTitle('Notifications', context).animate().fade(delay: 200.ms).slideX(),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                children: [
                  _buildSwitchTile(
                    'Daily Reminders', 
                    Icons.notifications_active_rounded, 
                    settings.notificationsEnabled, 
                    (val) => notifier.toggleNotifications(val),
                    context,
                  ),
                ],
              ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 32),
              
              _buildSectionTitle('Support', context).animate().fade(delay: 400.ms).slideX(),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                children: [
                  _buildListTile('Report a Bug / Feedback', Icons.bug_report_rounded, textColor, context, onTap: () {}),
                  _buildDivider(context),
                  _buildListTile('Help Center', Icons.help_outline_rounded, textColor, context, onTap: () {}),
                ],
              ).animate().fade(delay: 500.ms).slideY(begin: 0.1),
              
              const SizedBox(height: 32),
              
              _buildSectionTitle('Account', context).animate().fade(delay: 600.ms).slideX(),
              const SizedBox(height: 12),
              _buildSettingsCard(
                context,
                children: [
                  _buildListTile('Log Out', Icons.logout_rounded, AppColors.warning, context, onTap: () async {
                    await ProgressRepository().saveLocalState('is_onboarded', '0');
                    await SupabaseConfig.client.auth.signOut();
                  }),
                  _buildDivider(context),
                  _buildListTile('Delete Account', Icons.delete_forever_rounded, AppColors.error, context, onTap: () {
                    _showDeleteAccountDialog(context);
                  }),
                ],
              ).animate().fade(delay: 700.ms).slideY(begin: 0.1),

              const SizedBox(height: 48),
              
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt_rounded, color: AppColors.primaryGreenDark),
                    const SizedBox(width: 8),
                    Text(
                      'Powered by Crexst Technologies',
                      style: AppTypography.labelMedium.copyWith(
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1, duration: 2.seconds),
              
              const SizedBox(height: 100), // Padding for floating nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Material(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: AppTypography.labelLarge.copyWith(
        color: AppColors.textMutedLight,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, ValueChanged<bool> onChanged, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.waterBlue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.waterBlue, size: 24),
      ),
      title: Text(title, style: AppTypography.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.w600)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.surfaceLight,
        activeTrackColor: AppColors.primaryGreen,
        inactiveThumbColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
        inactiveTrackColor: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, Color contentColor, BuildContext context, {required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: contentColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: contentColor, size: 24),
      ),
      title: Text(title, style: AppTypography.bodyLarge.copyWith(color: contentColor, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.borderDark : AppColors.borderLight),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softCardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 48),
              ),
              const SizedBox(height: 24),
              Text('Delete Account?', style: AppTypography.headlineMedium.copyWith(color: textColor)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('CANCEL', style: AppTypography.labelLarge.copyWith(color: AppColors.textMutedLight)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please contact support to permanently delete your account.', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
                            backgroundColor: AppColors.error,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Text('DELETE', style: AppTypography.labelLarge.copyWith(color: Colors.white)),
                    ),
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
