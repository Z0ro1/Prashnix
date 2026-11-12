import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/state/user_state.dart';
import '../../domain/services/heart_engine_service.dart';
import '../../../leaderboard/data/repositories/cloud_sync_repository.dart';
import '../../../profile/data/repositories/progress_repository.dart';

part 'heart_economy_provider.g.dart';

@Riverpod(keepAlive: true)
class HeartEconomy extends _$HeartEconomy {
  late final HeartEngineService _engine;
  late final CloudSyncRepository _cloudSync;
  final ProgressRepository _progressRepo = ProgressRepository();
  bool _isEvaluating = false;
  Timer? _periodicTimer;

  static const int maxDailyHeartAds = 4;

  @override
  int build() {
    _engine = HeartEngineService();
    _cloudSync = CloudSyncRepository();

    // Trigger immediate evaluation on provider construction
    Future.microtask(() => checkAndApplyRegeneration());

    // Background timer: runs every 30 seconds to catch midnight IST reset & rolling regens
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkAndApplyRegeneration();
    });

    ref.onDispose(() {
      _periodicTimer?.cancel();
    });

    return 0; 
  }

  String _getIstDateString([DateTime? date]) {
    final istLocation = _engine.istLocation;
    final istTime = tz.TZDateTime.from((date ?? DateTime.now()).toUtc(), istLocation);
    return '${istTime.year}-${istTime.month.toString().padLeft(2, '0')}-${istTime.day.toString().padLeft(2, '0')}';
  }

  /// Evaluates passive regeneration (1 heart every 2 hours)
  /// and midnight IST resets based on SQLite persisted checkpoints.
  Future<HeartEngineResult> checkAndApplyRegeneration() async {
    if (_isEvaluating) {
      return HeartEngineResult(
        updatedHearts: ref.read(userStoreProvider).heartCount,
        nextRegenTime: DateTime.now().toUtc(),
        secondsUntilNextRegen: state,
      );
    }
    _isEvaluating = true;

    try {
      final user = ref.read(userStoreProvider);
      final todayIstStr = _getIstDateString();
      final lastRefillDate = await _progressRepo.getLocalState('last_heart_refill_date');

      // 1. Midnight IST Daily Reset
      // If we crossed into a new day (IST), refill hearts completely to 5 and reset ad counters.
      if (lastRefillDate == null) {
        await _progressRepo.saveLocalState('last_heart_refill_date', todayIstStr);
      } else if (lastRefillDate != todayIstStr) {
        debugPrint('[HeartEconomy] Midnight IST triggered! Resetting to 5 hearts and resetting ad limits.');
        await _progressRepo.saveLocalState('last_heart_refill_date', todayIstStr);
        await _progressRepo.saveLocalState('current_hearts', '${HeartEngineService.maxHearts}');
        await _progressRepo.saveLocalState('ad_hearts_date', todayIstStr);
        await _progressRepo.saveLocalState('ad_hearts_count', '0');
        await _progressRepo.saveLocalState('ad_date', todayIstStr);
        await _progressRepo.saveLocalState('ad_count', '0');
        await _progressRepo.saveLocalState('last_heart_regen_time', DateTime.now().toUtc().toIso8601String());

        ref.read(userStoreProvider.notifier).updateHearts(HeartEngineService.maxHearts);
        _cloudSync.syncProgressToCloud(
          xp: user.totalXp,
          streak: user.streakCount,
          hearts: HeartEngineService.maxHearts,
        );
        state = 0;
        return HeartEngineResult(
          updatedHearts: HeartEngineService.maxHearts,
          nextRegenTime: DateTime.now().toUtc(),
          secondsUntilNextRegen: 0,
        );
      }

      // 2. Rolling 2-Hour Passive Regeneration
      final lastRegenStr = await _progressRepo.getLocalState('last_heart_regen_time');
      DateTime lastRegenTime;
      if (lastRegenStr != null) {
        lastRegenTime = DateTime.tryParse(lastRegenStr) ?? DateTime.now().toUtc();
      } else {
        lastRegenTime = DateTime.now().toUtc();
        await _progressRepo.saveLocalState('last_heart_regen_time', lastRegenTime.toIso8601String());
      }

      final result = _engine.calculateRegeneratedHearts(user.heartCount, lastRegenTime);

      if (result.updatedHearts != user.heartCount) {
        ref.read(userStoreProvider.notifier).updateHearts(result.updatedHearts);
        await _progressRepo.saveLocalState('current_hearts', result.updatedHearts.toString());
        
        _cloudSync.syncProgressToCloud(
          xp: user.totalXp,
          streak: user.streakCount,
          hearts: result.updatedHearts,
        );
      }

      await _progressRepo.saveLocalState('last_heart_regen_time', result.nextRegenTime.toUtc().toIso8601String());
      state = result.secondsUntilNextRegen;
      return result;
    } catch (e) {
      debugPrint('[HeartEconomy] Error during heart regeneration check: $e');
      return HeartEngineResult(
        updatedHearts: ref.read(userStoreProvider).heartCount,
        nextRegenTime: DateTime.now().toUtc(),
        secondsUntilNextRegen: state,
      );
    } finally {
      _isEvaluating = false;
    }
  }

  void evaluateRegeneration(DateTime lastRegenTime) {
    checkAndApplyRegeneration();
  }

  /// Deducts 2 hearts when starting a lesson.
  /// If hearts drop below max (from 5 to 3), starts the 2-hour regeneration timer.
  bool attemptLessonLaunch() {
    final user = ref.read(userStoreProvider);
    if (_engine.canLaunchLesson(user.heartCount)) {
      final previousHearts = user.heartCount;
      final newHearts = previousHearts - HeartEngineService.heartCostPerLesson;
      
      ref.read(userStoreProvider.notifier).updateHearts(newHearts);
      _progressRepo.saveLocalState('current_hearts', newHearts.toString());
      
      // If we just dropped from max hearts, start the regen timer from right now
      if (previousHearts >= HeartEngineService.maxHearts) {
        final nowUtc = DateTime.now().toUtc();
        _progressRepo.saveLocalState('last_heart_regen_time', nowUtc.toIso8601String());
        state = HeartEngineService.regenIntervalMinutes * 60;
      }

      _cloudSync.syncProgressToCloud(
        xp: user.totalXp,
        streak: user.streakCount,
        hearts: newHearts,
      );
      return true;
    }
    return false;
  }

  void applyMistakePenalty() {
    // Zero deduction on wrong answers as per requirements
  }

  void applyStreakBonus(int consecutiveCorrect) {
    final bonus = _engine.calculateStreakBonus(consecutiveCorrect);
    if (bonus > 0) {
      final user = ref.read(userStoreProvider);
      final newHearts = (user.heartCount + bonus).clamp(0, HeartEngineService.maxHearts);
      ref.read(userStoreProvider.notifier).updateHearts(newHearts);
      _progressRepo.saveLocalState('current_hearts', newHearts.toString());
      if (newHearts >= HeartEngineService.maxHearts) {
        state = 0;
      }
    }
  }

  void addHearts(int amount) {
    final user = ref.read(userStoreProvider);
    final newHearts = (user.heartCount + amount).clamp(0, HeartEngineService.maxHearts);
    ref.read(userStoreProvider.notifier).updateHearts(newHearts);
    _progressRepo.saveLocalState('current_hearts', newHearts.toString());
    
    if (newHearts >= HeartEngineService.maxHearts) {
      state = 0;
      _progressRepo.saveLocalState('last_heart_regen_time', DateTime.now().toUtc().toIso8601String());
    }
    
    _cloudSync.syncProgressToCloud(
      xp: user.totalXp,
      streak: user.streakCount,
      hearts: newHearts,
    );
  }

  void refillFull() {
    addHearts(HeartEngineService.maxHearts);
  }

  Future<int> getDailyHeartAdCount() async {
    final todayStr = _getIstDateString();
    final dateStr = await _progressRepo.getLocalState('ad_hearts_date') ?? await _progressRepo.getLocalState('ad_date');
    final countStr = await _progressRepo.getLocalState('ad_hearts_count') ?? await _progressRepo.getLocalState('ad_count');

    if (dateStr == todayStr) {
      return int.tryParse(countStr ?? '0') ?? 0;
    }
    return 0; // New day (midnight IST reset), return 0
  }

  Future<bool> canWatchHeartAd() async {
    final currentCount = await getDailyHeartAdCount();
    final user = ref.read(userStoreProvider);
    return currentCount < maxDailyHeartAds && user.heartCount < HeartEngineService.maxHearts;
  }

  /// Claims reward for watching an ad: grants +2 hearts up to max 5.
  Future<bool> rewardAdWatched() async {
    // Check and apply any pending regeneration / reset first
    await checkAndApplyRegeneration();

    final user = ref.read(userStoreProvider);
    final todayStr = _getIstDateString();
    final currentCount = await getDailyHeartAdCount();

    if (currentCount >= maxDailyHeartAds) {
      debugPrint('[HeartEconomy] Cannot reward: daily ad limit reached ($currentCount/$maxDailyHeartAds)');
      return false; // Limit reached: max 4 ads per day
    }

    if (user.heartCount >= HeartEngineService.maxHearts) {
      debugPrint('[HeartEconomy] Cannot reward: user already at full hearts (${user.heartCount}/5)');
      return false; // Already full
    }

    final newCount = currentCount + 1;
    await _progressRepo.saveLocalState('ad_hearts_date', todayStr);
    await _progressRepo.saveLocalState('ad_hearts_count', newCount.toString());
    await _progressRepo.saveLocalState('ad_date', todayStr);
    await _progressRepo.saveLocalState('ad_count', newCount.toString());
    
    final newHearts = (user.heartCount + 2).clamp(0, HeartEngineService.maxHearts);
    ref.read(userStoreProvider.notifier).updateHearts(newHearts);
    await _progressRepo.saveLocalState('current_hearts', newHearts.toString());
    
    if (newHearts >= HeartEngineService.maxHearts) {
      state = 0;
      await _progressRepo.saveLocalState('last_heart_regen_time', DateTime.now().toUtc().toIso8601String());
    } else {
      // Still below max: recalculate timer
      final lastRegenStr = await _progressRepo.getLocalState('last_heart_regen_time');
      final lastRegenTime = lastRegenStr != null ? (DateTime.tryParse(lastRegenStr) ?? DateTime.now().toUtc()) : DateTime.now().toUtc();
      final eval = _engine.calculateRegeneratedHearts(newHearts, lastRegenTime);
      state = eval.secondsUntilNextRegen;
    }

    _cloudSync.syncProgressToCloud(
      xp: user.totalXp,
      streak: user.streakCount,
      hearts: newHearts,
    );
    
    debugPrint('[HeartEconomy] Successfully rewarded ad! Hearts: ${user.heartCount} -> $newHearts, Ads today: $newCount/$maxDailyHeartAds');
    return true;
  }
}
