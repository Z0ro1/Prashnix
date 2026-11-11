import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/services/widget_sync_service.dart';
import '../../../../core/state/user_state.dart';
import '../../domain/models/streak_model.dart';
import '../../domain/services/heart_engine_service.dart';
import '../../../profile/data/repositories/progress_repository.dart';
import '../../../leaderboard/data/repositories/cloud_sync_repository.dart';

final streakProvider = NotifierProvider<StreakNotifier, StreakInfo>(StreakNotifier.new);

class StreakNotifier extends Notifier<StreakInfo> {
  final ProgressRepository _repo = ProgressRepository();
  final CloudSyncRepository _cloudSync = CloudSyncRepository();
  late final tz.Location _istLocation;

  @override
  StreakInfo build() {
    _istLocation = HeartEngineService().istLocation;
    Future.microtask(() => _loadStreakData());
    return const StreakInfo();
  }

  String getIstTodayString([DateTime? date]) {
    final ist = tz.TZDateTime.from((date ?? DateTime.now()).toUtc(), _istLocation);
    return '${ist.year}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
  }

  String getIstYesterdayString() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return getIstTodayString(yesterday);
  }

  DateTime parseIstDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Future<void> _loadStreakData() async {
    try {
      final currentStreakStr = await _repo.getLocalState('streak_count') ?? '0';
      final longestStreakStr = await _repo.getLocalState('streak_longest') ?? '0';
      final freezesStr = await _repo.getLocalState('streak_freezes') ?? '2';
      final isEquippedStr = await _repo.getLocalState('streak_freeze_equipped') ?? '1';
      final activeDatesStr = await _repo.getLocalState('streak_active_dates');
      final frozenDatesStr = await _repo.getLocalState('streak_frozen_dates');
      final dailyMetaStr = await _repo.getLocalState('streak_daily_activity');
      final lastActiveDate = await _repo.getLocalState('streak_last_active_date');

      int currentStreak = int.tryParse(currentStreakStr) ?? 0;
      int longestStreak = int.tryParse(longestStreakStr) ?? 0;
      int freezes = int.tryParse(freezesStr) ?? 2;
      bool isEquipped = isEquippedStr == '1';

      Set<String> activeDates = {};
      if (activeDatesStr != null && activeDatesStr.isNotEmpty) {
        try {
          final list = jsonDecode(activeDatesStr) as List;
          activeDates = list.map((e) => e.toString()).toSet();
        } catch (_) {}
      }

      Set<String> frozenDates = {};
      if (frozenDatesStr != null && frozenDatesStr.isNotEmpty) {
        try {
          final list = jsonDecode(frozenDatesStr) as List;
          frozenDates = list.map((e) => e.toString()).toSet();
        } catch (_) {}
      }

      Map<String, DailyActivityRecord> dailyActivity = {};
      if (dailyMetaStr != null && dailyMetaStr.isNotEmpty) {
        try {
          final map = jsonDecode(dailyMetaStr) as Map<String, dynamic>;
          dailyActivity = map.map((key, val) => MapEntry(
            key,
            DailyActivityRecord.fromMap(val as Map<String, dynamic>),
          ));
        } catch (_) {}
      }

      // Reconcile streak state based on calendar days elapsed
      final todayStr = getIstTodayString();
      final yesterdayStr = getIstYesterdayString();

      if (lastActiveDate != null && lastActiveDate != todayStr) {
        final lastDate = parseIstDate(lastActiveDate);
        final todayDate = parseIstDate(todayStr);
        final differenceInDays = todayDate.difference(lastDate).inDays;

        if (differenceInDays == 1) {
          // Practiced yesterday - streak is active and waiting for today's lesson
        } else if (differenceInDays == 2) {
          // Missed exactly yesterday: Check if Streak Freeze protects it!
          if (isEquipped && freezes > 0) {
            freezes--;
            frozenDates.add(yesterdayStr);
            await _repo.saveLocalState('streak_freezes', freezes.toString());
            await _repo.saveLocalState('streak_frozen_dates', jsonEncode(frozenDates.toList()));
            debugPrint('[StreakNotifier] Streak freeze consumed to protect yesterday ($yesterdayStr)');
          } else {
            // No freeze available: streak broken
            currentStreak = 0;
            await _repo.saveLocalState('streak_count', '0');
            ref.read(userStoreProvider.notifier).updateStreak(0);
          }
        } else if (differenceInDays > 2) {
          // Missed multiple days: Streak broken
          currentStreak = 0;
          await _repo.saveLocalState('streak_count', '0');
          ref.read(userStoreProvider.notifier).updateStreak(0);
        }
      }

      longestStreak = math.max(longestStreak, currentStreak);

      state = StreakInfo(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        streakFreezes: freezes,
        isFreezeEquipped: isEquipped,
        activeDates: activeDates,
        frozenDates: frozenDates,
        dailyActivity: dailyActivity,
        lastActiveDate: lastActiveDate,
      );

      // Sync updated streak to native home screen widget
      final user = ref.read(userStoreProvider);
      final isDoneToday = activeDates.contains(todayStr);
      WidgetSyncService.syncStreakWidget(
        streakCount: currentStreak,
        isPracticedToday: isDoneToday,
        heartCount: user.heartCount,
      );
    } catch (e) {
      debugPrint('[StreakNotifier] Error loading streak data: $e');
    }
  }

  /// Records practice activity (completing a lesson or quiz).
  /// Automatically computes streak progression, IST date, and cloud sync.
  Future<bool> recordDailyActivity({int xpEarned = 30}) async {
    final todayStr = getIstTodayString();
    final yesterdayStr = getIstYesterdayString();

    final activeDates = Set<String>.from(state.activeDates);
    final dailyActivity = Map<String, DailyActivityRecord>.from(state.dailyActivity);
    final currentRecord = dailyActivity[todayStr] ?? const DailyActivityRecord();

    final isFirstPracticeToday = !activeDates.contains(todayStr);

    int newStreak = state.currentStreak;
    if (isFirstPracticeToday) {
      activeDates.add(todayStr);

      if (state.lastActiveDate == yesterdayStr || state.frozenDates.contains(yesterdayStr)) {
        // Consecutive day
        newStreak = state.currentStreak + 1;
      } else if (state.lastActiveDate == null || state.currentStreak == 0) {
        // First practice ever or starting fresh
        newStreak = 1;
      } else {
        // Gap occurred earlier and restarted today
        newStreak = 1;
      }
    }

    final newLongest = math.max(state.longestStreak, newStreak);

    final updatedRecord = DailyActivityRecord(
      lessonsCompleted: currentRecord.lessonsCompleted + 1,
      xpEarned: currentRecord.xpEarned + xpEarned,
    );
    dailyActivity[todayStr] = updatedRecord;

    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      activeDates: activeDates,
      dailyActivity: dailyActivity,
      lastActiveDate: todayStr,
    );

    // Save ground truth to SQLite
    await _repo.saveLocalState('streak_count', newStreak.toString());
    await _repo.saveLocalState('streak_longest', newLongest.toString());
    await _repo.saveLocalState('streak_active_dates', jsonEncode(activeDates.toList()));
    await _repo.saveLocalState('streak_daily_activity', jsonEncode(
      dailyActivity.map((k, v) => MapEntry(k, v.toMap())),
    ));
    await _repo.saveLocalState('streak_last_active_date', todayStr);

    // Update UserStore ground truth
    ref.read(userStoreProvider.notifier).updateStreak(newStreak);

    // Sync to Supabase
    final user = ref.read(userStoreProvider);
    _cloudSync.syncProgressToCloud(
      xp: user.totalXp,
      streak: newStreak,
      hearts: user.heartCount,
    );

    // Sync real-time streak extension to home screen widget
    final isDoneToday = activeDates.contains(todayStr);
    WidgetSyncService.syncStreakWidget(
      streakCount: newStreak,
      isPracticedToday: isDoneToday,
      heartCount: user.heartCount,
    );

    return isFirstPracticeToday;
  }

  Future<void> equipOrRefillFreeze() async {
    const maxFreezes = 2;
    if (state.streakFreezes >= maxFreezes && state.isFreezeEquipped) {
      return;
    }

    final newFreezes = math.min(maxFreezes, state.streakFreezes + 1);
    state = state.copyWith(
      streakFreezes: newFreezes,
      isFreezeEquipped: true,
    );

    await _repo.saveLocalState('streak_freezes', newFreezes.toString());
    await _repo.saveLocalState('streak_freeze_equipped', '1');
  }
}
