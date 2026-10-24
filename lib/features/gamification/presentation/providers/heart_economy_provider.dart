import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/state/user_state.dart';
import '../../domain/services/heart_engine_service.dart';
import '../../../leaderboard/data/repositories/cloud_sync_repository.dart';
import '../../../profile/data/repositories/progress_repository.dart';

part 'heart_economy_provider.g.dart';

@riverpod
class HeartEconomy extends _$HeartEconomy {
  late final HeartEngineService _engine;
  late final CloudSyncRepository _cloudSync;

  @override
  int build() {
    _engine = HeartEngineService();
    _cloudSync = CloudSyncRepository();
    // Return seconds until next regen
    return 0; 
  }

  void evaluateRegeneration(DateTime lastRegenTime) {
    final user = ref.read(userStoreProvider);
    
    final result = _engine.calculateRegeneratedHearts(user.heartCount, lastRegenTime);
    
    if (result.updatedHearts != user.heartCount) {
      ref.read(userStoreProvider.notifier).updateHearts(result.updatedHearts);
      
      // Sync the new state
      _cloudSync.syncProgressToCloud(
        xp: user.totalXp,
        streak: user.streakCount,
        hearts: result.updatedHearts,
      );
    }

    state = result.secondsUntilNextRegen;
  }

  bool attemptLessonLaunch() {
    final user = ref.read(userStoreProvider);
    if (_engine.canLaunchLesson(user.heartCount)) {
      final newHearts = user.heartCount - HeartEngineService.heartCostPerLesson;
      ref.read(userStoreProvider.notifier).updateHearts(newHearts);
      return true;
    }
    return false;
  }

  void applyMistakePenalty() {
    final user = ref.read(userStoreProvider);
    final newHearts = (user.heartCount - HeartEngineService.heartPenaltyPerMistake).clamp(0, HeartEngineService.maxHearts);
    ref.read(userStoreProvider.notifier).updateHearts(newHearts);
  }

  void applyStreakBonus(int consecutiveCorrect) {
    final bonus = _engine.calculateStreakBonus(consecutiveCorrect);
    if (bonus > 0) {
      final user = ref.read(userStoreProvider);
      final newHearts = (user.heartCount + bonus).clamp(0, HeartEngineService.maxHearts);
      ref.read(userStoreProvider.notifier).updateHearts(newHearts);
    }
  }

  void addHearts(int amount) {
    final user = ref.read(userStoreProvider);
    final newHearts = (user.heartCount + amount).clamp(0, HeartEngineService.maxHearts);
    ref.read(userStoreProvider.notifier).updateHearts(newHearts);
    
    _cloudSync.syncProgressToCloud(
      xp: user.totalXp,
      streak: user.streakCount,
      hearts: newHearts,
    );
  }

  Future<bool> rewardAdWatched() async {
    final user = ref.read(userStoreProvider);
    // Check daily limits
    final repo = ProgressRepository();
    final dateStr = await repo.getLocalState('ad_date');
    final countStr = await repo.getLocalState('ad_count');

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    int currentCount = 0;
    if (dateStr == todayStr) {
      currentCount = int.tryParse(countStr ?? '0') ?? 0;
    } else {
      await repo.saveLocalState('ad_date', todayStr);
    }

    if (currentCount >= 4) {
      return false; // Limit reached
    }

    await repo.saveLocalState('ad_count', (currentCount + 1).toString());
    
    final newHearts = (user.heartCount + 2).clamp(0, HeartEngineService.maxHearts);
    ref.read(userStoreProvider.notifier).updateHearts(newHearts);
    
    _cloudSync.syncProgressToCloud(
      xp: user.totalXp,
      streak: user.streakCount,
      hearts: newHearts,
    );
    
    return true;
  }

  void completeLesson() {
    final user = ref.read(userStoreProvider);
    ref.read(userStoreProvider.notifier).addXp(50);
    ref.read(userStoreProvider.notifier).incrementStreak();
    
    _cloudSync.syncProgressToCloud(
      xp: user.totalXp + 50,
      streak: user.streakCount + 1,
      hearts: user.heartCount,
    );
  }
}
