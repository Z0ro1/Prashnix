import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../features/profile/data/repositories/progress_repository.dart';
import '../../features/gamification/domain/services/heart_engine_service.dart';

/// Enum to define what the user is watching a rewarded ad for
enum AdRewardType {
  heartRefill,
  weeklyTest,
  weeklyXpBoost,
}

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  
  bool _isRewardedLoading = false;
  bool _isInterstitialLoading = false;

  int _rewardedRetryAttempt = 0;
  int _interstitialRetryAttempt = 0;
  Timer? _rewardedRetryTimer;
  Timer? _interstitialRetryTimer;

  DateTime? _lastInterstitialTime;
  static const Duration _interstitialCooldown = Duration(minutes: 3);
  
  final ProgressRepository _repo = ProgressRepository();

  // Test Ad Unit IDs (Google Sample IDs)
  static const String _defaultAndroidRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _defaultIosRewardedId = 'ca-app-pub-3940256099942544/1712485313';
  
  static const String _defaultAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _defaultIosInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  String get rewardedAdUnitId {
    if (!Platform.isAndroid && !Platform.isIOS) return '';
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_REWARDED_ID'] ??
          dotenv.env['ADMOB_REWARDED_AD_UNIT_ID'] ??
          _defaultAndroidRewardedId;
    } else {
      return dotenv.env['ADMOB_IOS_REWARDED_ID'] ?? _defaultIosRewardedId;
    }
  }

  String get interstitialAdUnitId {
    if (!Platform.isAndroid && !Platform.isIOS) return '';
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_ANDROID_INTERSTITIAL_ID'] ??
          dotenv.env['ADMOB_INTERSTITIAL_AD_UNIT_ID'] ??
          _defaultAndroidInterstitialId;
    } else {
      return dotenv.env['ADMOB_IOS_INTERSTITIAL_ID'] ?? _defaultIosInterstitialId;
    }
  }

  bool get isRewardedAdReady => _rewardedAd != null;
  bool get isInterstitialAdReady => _interstitialAd != null;
  bool get isRewardedLoading => _isRewardedLoading;

  // ---------------------------------------------------------
  // INITIALIZATION & LOADING
  // ---------------------------------------------------------

  void preLoadAds() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  void _loadRewardedAd() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_rewardedAd != null || _isRewardedLoading) return;
    
    _isRewardedLoading = true;
    _rewardedRetryTimer?.cancel();

    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobService] Rewarded ad loaded successfully.');
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _rewardedRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobService] Rewarded ad failed to load: ${error.message} (Code: ${error.code})');
          _rewardedAd = null;
          _isRewardedLoading = false;
          _rewardedRetryAttempt++;
          
          final delaySec = math.min(64, math.pow(2, _rewardedRetryAttempt).toInt());
          debugPrint('[AdMobService] Retrying rewarded ad load in $delaySec seconds (attempt $_rewardedRetryAttempt)...');
          _rewardedRetryTimer = Timer(Duration(seconds: delaySec), () {
            _loadRewardedAd();
          });
        },
      ),
    );
  }

  void _loadInterstitialAd() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;
    
    _isInterstitialLoading = true;
    _interstitialRetryTimer?.cancel();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdMobService] Interstitial ad loaded successfully.');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialRetryAttempt = 0;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdMobService] Interstitial ad failed to load: ${error.message} (Code: ${error.code})');
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _interstitialRetryAttempt++;
          
          final delaySec = math.min(64, math.pow(2, _interstitialRetryAttempt).toInt());
          debugPrint('[AdMobService] Retrying interstitial ad load in $delaySec seconds (attempt $_interstitialRetryAttempt)...');
          _interstitialRetryTimer = Timer(Duration(seconds: delaySec), () {
            _loadInterstitialAd();
          });
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // REWARDED ADS (User Opt-in: Hearts, Weekly Test, Weekly XP)
  // ---------------------------------------------------------

  /// Request to show a rewarded ad. Handles all business logic caps.
  /// [onAdClosed] is always invoked when the ad is closed, dismissed, or errors,
  /// guaranteeing UI loading states never freeze.
  Future<void> showRewardedAd({
    required AdRewardType type,
    required int currentHearts,
    required VoidCallback onEarnedReward,
    VoidCallback? onAdClosed,
    required Function(String error) onError,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      onError("Rewarded ads are only supported on Android and iOS devices.");
      onAdClosed?.call();
      return;
    }

    // 1. Business Logic Checks
    if (type == AdRewardType.heartRefill) {
      if (currentHearts >= HeartEngineService.maxHearts) {
        onError("You already have full hearts (${HeartEngineService.maxHearts}/${HeartEngineService.maxHearts})! Go play!");
        onAdClosed?.call();
        return;
      }
      
      final dailyHeartAds = await _getDailyCount('ad_hearts_date', 'ad_hearts_count');
      if (dailyHeartAds >= 4) {
        onError("Daily limit reached. You can only watch 4 ads for hearts per day.");
        onAdClosed?.call();
        return;
      }
    } else if (type == AdRewardType.weeklyXpBoost) {
      final canWatchWeekly = await _canWatchWeekly('ad_weekly_xp_date');
      if (!canWatchWeekly) {
        onError("This +50 XP boost offer is only available once a week.");
        onAdClosed?.call();
        return;
      }
    }

    // 2. Ad Readiness Check
    if (_rewardedAd == null) {
      if (_isRewardedLoading) {
        onError('Ad is loading, please try again in a moment.');
      } else {
        onError('Ad is not ready yet. Please try again in a few seconds.');
        _loadRewardedAd();
      }
      onAdClosed?.call();
      return;
    }

    // 3. Show Ad
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Prepare next ad
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMobService] Rewarded ad failed to show: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
        onError('Failed to show ad: ${error.message}');
        onAdClosed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) async {
        if (type == AdRewardType.weeklyXpBoost) {
          await _recordWeeklyAction('ad_weekly_xp_date');
        }
        onEarnedReward();
      },
    );
  }

  // ---------------------------------------------------------
  // INTERSTITIAL ADS (Forced: Quit Lesson, Complete Lesson)
  // ---------------------------------------------------------

  /// Call this when a user finishes a quiz or quits mid-lesson.
  /// Interstitials are rate-limited to at most once per 3 minutes (policy best practice).
  /// [onAdClosed] is ALWAYS called so navigation continues without interruption.
  Future<void> showInterstitialAd({
    required VoidCallback onAdClosed,
    bool force = false,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      onAdClosed();
      return;
    }

    // Frequency capping check (Policy best practice: minimum 3 minutes between interstitials)
    if (!force && _lastInterstitialTime != null) {
      final elapsed = DateTime.now().difference(_lastInterstitialTime!);
      if (elapsed < _interstitialCooldown) {
        debugPrint('[AdMobService] Interstitial skipped due to frequency cap (${elapsed.inSeconds}s < ${_interstitialCooldown.inSeconds}s)');
        onAdClosed();
        return;
      }
    }

    // If the ad failed to load or isn't ready, let the user proceed immediately
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      onAdClosed();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialTime = DateTime.now();
        _loadInterstitialAd(); // Preload next interstitial
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMobService] Interstitial failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
        onAdClosed();
      },
    );

    _interstitialAd!.show();
  }

  // ---------------------------------------------------------
  // HELPERS FOR LIMITS
  // ---------------------------------------------------------

  String _getIstDateString() {
    final engine = HeartEngineService();
    final istTime = tz.TZDateTime.from(DateTime.now().toUtc(), engine.istLocation);
    return '${istTime.year}-${istTime.month.toString().padLeft(2, '0')}-${istTime.day.toString().padLeft(2, '0')}';
  }

  Future<int> _getDailyCount(String dateKey, String countKey) async {
    final dateStr = _getIstDateString();
    final savedDate = await _repo.getLocalState(dateKey) ?? await _repo.getLocalState('ad_date');
    final countStr = await _repo.getLocalState(countKey) ?? await _repo.getLocalState('ad_count') ?? '0';
    
    if (savedDate == dateStr) {
      return int.tryParse(countStr) ?? 0;
    }
    return 0; // New day (midnight IST reset), reset count
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
