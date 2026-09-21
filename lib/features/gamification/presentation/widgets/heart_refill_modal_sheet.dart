import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/services/ad_reward_service.dart';
import '../providers/heart_economy_provider.dart';

class HeartRefillModalSheet extends ConsumerStatefulWidget {
  const HeartRefillModalSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HeartRefillModalSheet(),
    );
  }

  @override
  ConsumerState<HeartRefillModalSheet> createState() => _HeartRefillModalSheetState();
}

class _HeartRefillModalSheetState extends ConsumerState<HeartRefillModalSheet> {
  final AdRewardService _adService = AdRewardService();
  bool _isLoadingAd = false;

  @override
  void initState() {
    super.initState();
    _adService.initialize();
  }

  void _watchAd() {
    setState(() => _isLoadingAd = true);
    
    _adService.showHeartRefillAd(
      onRewardEarned: () async {
        final success = await ref.read(heartEconomyProvider.notifier).rewardAdWatched();
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('+1 Heart restored!')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Daily limit reached (4/4)')),
            );
          }
        }
      },
      onAdClosed: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
          Navigator.of(context).pop();
        }
      },
      onAdFailed: () {
        if (mounted) {
          setState(() => _isLoadingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load ad. Please try again later.')),
          );
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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
              style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You need at least 1 heart to start a lesson.',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Watch Short Video (+1 Heart)',
              onPressed: _isLoadingAd ? null : _watchAd,
              variant: ButtonVariant.primaryMint,
              icon: _isLoadingAd ? Icons.hourglass_empty : Icons.play_circle_fill,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Wait for Hourly Auto-Regen',
              onPressed: () => Navigator.of(context).pop(),
              variant: ButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }
}
