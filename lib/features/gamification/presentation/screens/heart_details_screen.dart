import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/state/user_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/ad_service.dart';
import '../widgets/heart_regen_timer_widget.dart';
import '../providers/heart_economy_provider.dart';

class HeartDetailsScreen extends ConsumerStatefulWidget {
  const HeartDetailsScreen({super.key});

  @override
  ConsumerState<HeartDetailsScreen> createState() => _HeartDetailsScreenState();
}

class _HeartDetailsScreenState extends ConsumerState<HeartDetailsScreen> {
  int _adsWatchedToday = 0;
  bool _isLoadingAd = false;
  
  @override
  void initState() {
    super.initState();
    _loadAdCount();
    AdMobService().preLoadAds();
  }

  Future<void> _loadAdCount() async {
    final count = await ref.read(heartEconomyProvider.notifier).getDailyHeartAdCount();
    if (mounted) {
      setState(() {
        _adsWatchedToday = count;
      });
    }
  }

  Color _getHeartColor(int hearts) {
    if (hearts >= 5) return AppColors.bpmRed; // Full
    if (hearts >= 2) return AppColors.foxOrange; // Ready for lesson
    return Colors.grey; // Insufficient (< 2)
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userStoreProvider);
    final hearts = state.heartCount;
    final heartColor = _getHeartColor(hearts);
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Your Hearts', style: AppTypography.headlineSmall.copyWith(color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.wait([
            ref.read(userStoreProvider.notifier).refreshProfile(),
            _loadAdCount(),
          ]);
        },
        color: AppColors.bpmRed,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        displacement: 40,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Heart Regen Timer
              const HeartRegenTimerWidget(),
              const SizedBox(height: 40),

              // Big Heart Animation
              Icon(
                Icons.favorite,
                size: 120,
                color: heartColor,
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut),
              
              const SizedBox(height: 20),

              // Heart Count
              Text(
                '$hearts',
                style: AppTypography.displayHero.copyWith(
                  color: heartColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 80,
                ),
              ),
              
              Text(
                'Available Hearts',
                style: AppTypography.headlineMedium.copyWith(color: mutedColor),
              ),

              const SizedBox(height: 40),

              // Ad Button
              if (hearts < 5) ...[
                if (_adsWatchedToday >= 4)
                  Text(
                    'Daily Limit Reached (4/4 ads)',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                  )
                else ...[
                  Text(
                    '$_adsWatchedToday/4 Ads Watched Today (Resets at Midnight)',
                    style: AppTypography.bodySmall.copyWith(color: mutedColor),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingAd ? null : () => _watchAdForHearts(hearts),
                      icon: _isLoadingAd 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                        : const Icon(Icons.ondemand_video),
                      label: Text(
                        'Watch Ad (+2 Hearts)',
                        style: AppTypography.headlineMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.waterBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ]
              ] else
                Text(
                  'You have full hearts (5/5)! Go play!',
                  style: AppTypography.headlineMedium.copyWith(color: AppColors.primaryGreenDark, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 40),

              // Rules and Tips Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips & Rules',
                      style: AppTypography.headlineLarge.copyWith(color: textColor, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildRule(Icons.play_arrow, 'Each lesson costs 2 Hearts to start.', textColor),
                    _buildRule(Icons.verified, 'No reduction in hearts on wrong questions.', textColor),
                    _buildRule(Icons.timer, 'Hearts passively refill 1 per 2 hours (or fully at midnight IST).', textColor),
                    _buildRule(Icons.battery_charging_full, 'Max capacity is 5 Hearts.', textColor),
                    _buildRule(Icons.local_fire_department, 'Get a 5-answer streak to instantly recover 2 Hearts.', textColor),
                    _buildRule(Icons.ondemand_video, 'Watch up to 4 Ads per day to refill hearts (+2 Hearts each).', textColor),
                    _buildRule(Icons.block, 'Ads cannot be watched if you already have full Hearts (5/5).', textColor),
                    _buildRule(Icons.calendar_today, 'Daily ad limits reset automatically at midnight IST.', textColor),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildRule(IconData icon, String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.waterBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _watchAdForHearts(int currentHearts) {
    if (_adsWatchedToday >= HeartEconomy.maxDailyHeartAds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily ad limit reached (Max 4/day). Resets at midnight IST.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoadingAd = true);
    
    AdMobService().showRewardedAd(
      type: AdRewardType.heartRefill,
      currentHearts: currentHearts,
      onAdClosed: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
        }
      },
      onEarnedReward: () async {
        final success = await ref.read(heartEconomyProvider.notifier).rewardAdWatched();
        if (!mounted) return;
        setState(() => _isLoadingAd = false);
        await _loadAdCount();
        
        if (success) {
          messenger.showSnackBar(
            SnackBar(
              content: Text('+2 Hearts Claimed! (${ref.read(userStoreProvider).heartCount} ❤️)'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Could not claim hearts. Ad limit reached or hearts full.')),
          );
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() => _isLoadingAd = false);
        messenger.showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        );
      }
    );
  }
}
