import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/state/user_state.dart';
import '../providers/heart_economy_provider.dart';

class HeartRefillModalSheet extends ConsumerStatefulWidget {
  const HeartRefillModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HeartRefillModalSheet(),
    );
  }

  @override
  ConsumerState<HeartRefillModalSheet> createState() => _HeartRefillModalSheetState();
}

class _HeartRefillModalSheetState extends ConsumerState<HeartRefillModalSheet> {
  bool _isLoadingAd = false;
  int _dailyAdCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDailyAdCount();
  }

  Future<void> _loadDailyAdCount() async {
    final count = await ref.read(heartEconomyProvider.notifier).getDailyHeartAdCount();
    if (mounted) {
      setState(() => _dailyAdCount = count);
    }
  }

  void _watchAd() async {
    final currentHearts = ref.read(userStoreProvider).heartCount;
    if (_dailyAdCount >= HeartEconomy.maxDailyHeartAds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily limit reached (Max 4 ads/day). Resets at midnight IST.')),
      );
      return;
    }

    setState(() => _isLoadingAd = true);
    
    await AdMobService().showRewardedAd(
      type: AdRewardType.heartRefill,
      currentHearts: currentHearts,
      onAdClosed: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
        }
      },
      onEarnedReward: () async {
        final success = await ref.read(heartEconomyProvider.notifier).rewardAdWatched();
        if (mounted) {
          setState(() => _isLoadingAd = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('+2 Hearts restored! You have ${ref.read(userStoreProvider).heartCount} ❤️')),
            );
            Navigator.of(context).pop();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily limit reached (4/4 ads watched today)')),
            );
          }
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoadingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final remainingAds = (HeartEconomy.maxDailyHeartAds - _dailyAdCount).clamp(0, HeartEconomy.maxDailyHeartAds);
    final canWatch = remainingAds > 0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.only(bottom: 90),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1115).withValues(alpha: 0.8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            const Icon(
              Icons.favorite_border,
              color: AppColors.accentRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Out of Hearts!',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You need at least 2 hearts to start a lesson.',
              style: AppTextStyles.body.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              canWatch 
                  ? 'Daily Ads: $_dailyAdCount / ${HeartEconomy.maxDailyHeartAds} ($remainingAds left today)'
                  : 'Daily limit reached (4/4 ads). Resets at midnight IST.',
              style: AppTextStyles.label.copyWith(color: canWatch ? Colors.white60 : AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (canWatch) ...[
              CustomButton(
                text: 'Watch Video (+2 Hearts)',
                onPressed: _isLoadingAd ? null : _watchAd,
                variant: ButtonVariant.primaryMint,
                icon: _isLoadingAd ? Icons.hourglass_empty : Icons.play_circle_fill,
              ),
              const SizedBox(height: 16),
            ],
            CustomButton(
              text: 'Wait for Auto-Regen (1 heart / 2 hrs)',
              onPressed: () => Navigator.of(context).pop(),
              variant: ButtonVariant.outline,
            ),
          ],
        ),
        ),
      ),
      ),
    );
  }
}
