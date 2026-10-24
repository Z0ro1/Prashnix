import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../features/profile/data/repositories/progress_repository.dart';

/// Enum to define what the user is watching a rewarded ad for
enum AdRewardType {
  heartRefill,
  weeklyTest,
  weeklyXpBoost
}

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  
  bool _isRewardedLoading = false;
  bool _isInterstitialLoading = false;
  
  final ProgressRepository _repo = ProgressRepository();

  // Test Ad Unit IDs (Replace with real ones in production)
  final String _androidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  final String _iosRewardedId = 'ca-app-pub-3940256099942544/1712485313';
  
  final String _androidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  final String _iosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  String get rewardedAdUnitId => Platform.isAndroid ? _androidRewardedId : _iosRewardedId;
  String get interstitialAdUnitId => Platform.isAndroid ? _androidInterstitialId : _iosInterstitialId;

  // ---------------------------------------------------------
  // INITIALIZATION & LOADING
  // ---------------------------------------------------------

  void preLoadAds() {
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    if (_rewardedAd != null || _isRewardedLoading) return;
    _isRewardedLoading = true;

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    if (_interstitialAd != null || _isInterstitialLoading) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // REWARDED ADS (User Opt-in: Hearts, Weekly Test, Weekly XP)
  // ---------------------------------------------------------

  /// Request to show a rewarded ad. Handles all business logic caps.
  Future<void> showRewardedAd({
    required AdRewardType type,
    required int currentHearts,
    required Function() onEarnedReward,
    required Function(String error) onError,
  }) async {
    // 1. Business Logic Checks
    if (type == AdRewardType.heartRefill) {
      if (currentHearts >= 20) {
        onError("You got enough hearts to start a lesson! Go play!");
        return;
      }
      
      final dailyHeartAds = await _getDailyCount('ad_hearts_date', 'ad_hearts_count');
      if (dailyHeartAds >= 4) {
        onError("Daily limit reached. You can only watch 4 ads for hearts per day.");
        return;
      }
    } else if (type == AdRewardType.weeklyXpBoost) {
      final canWatchWeekly = await _canWatchWeekly('ad_weekly_xp_date');
      if (!canWatchWeekly) {
        onError("This +50 XP boost offer is only available once a week.");
        return;
      }
    }

    // 2. Ad Readiness Check
    if (_rewardedAd == null) {
      onError('Ad is not ready yet. Please try again in a few seconds.');
      _loadRewardedAd();
      return;
    }

    // 3. Show Ad
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Prepare next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        onError('Failed to show ad: ${error.message}');
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        // Record successful completion in local DB
        if (type == AdRewardType.heartRefill) {
           await _incrementDailyCount('ad_hearts_date', 'ad_hearts_count');
        } else if (type == AdRewardType.weeklyXpBoost) {
           await _recordWeeklyAction('ad_weekly_xp_date');
        }
        
        onEarnedReward();
      },
    );
  }

  // ---------------------------------------------------------
  // INTERSTITIAL ADS (Forced: Quit Lesson, Complete Lesson)
  // ---------------------------------------------------------

  /// Call this when a user clicks "Continue" on the results screen
  /// OR clicks "Cancel/Quit" mid-lesson.
  Future<void> showInterstitialAd({
    required Function() onAdClosed,
  }) async {
    // If the ad failed to load, don't punish the user. Let them proceed immediately.
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      onAdClosed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdClosed(); // Navigate to the next screen safely
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        onAdClosed();
      },
    );

    _interstitialAd!.show();
  }

  // ---------------------------------------------------------
  // HELPERS FOR LIMITS
  // ---------------------------------------------------------

  Future<int> _getDailyCount(String dateKey, String countKey) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    final savedDate = await _repo.getLocalState(dateKey);
    final countStr = await _repo.getLocalState(countKey) ?? '0';
    
    if (savedDate == dateStr) {
      return int.tryParse(countStr) ?? 0;
    }
    return 0; // New day, reset count
  }

  Future<void> _incrementDailyCount(String dateKey, String countKey) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    int current = await _getDailyCount(dateKey, countKey);
    await _repo.saveLocalState(dateKey, dateStr);
    await _repo.saveLocalState(countKey, (current + 1).toString());
  }

  Future<bool> _canWatchWeekly(String dateKey) async {
    final savedDateStr = await _repo.getLocalState(dateKey);
    if (savedDateStr == null) return true;
    
    final lastWatchDate = DateTime.tryParse(savedDateStr);
    if (lastWatchDate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastWatchDate);
    return difference.inDays >= 7; // Require 7 days to pass
  }
  
  Future<void> _recordWeeklyAction(String dateKey) async {
    final now = DateTime.now();
    await _repo.saveLocalState(dateKey, now.toIso8601String());
  }
}
