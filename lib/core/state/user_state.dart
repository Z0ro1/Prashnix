import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../config/supabase_config.dart';
import '../../features/profile/data/repositories/progress_repository.dart';

part 'user_state.g.dart';

class UserModel {
  final String username;
  final int heartCount;
  final int streakCount;
  final int totalXp;
  final String selectedDistrict;
  final String avatarId;

  const UserModel({
    this.username = '',
    this.heartCount = 5,
    this.streakCount = 0,
    this.totalXp = 0,
    this.selectedDistrict = 'Beginner District',
    this.avatarId = '',
  });

  UserModel copyWith({
    String? username,
    int? heartCount,
    int? streakCount,
    int? totalXp,
    String? selectedDistrict,
    String? avatarId,
  }) {
    return UserModel(
      username: username ?? this.username,
      heartCount: heartCount ?? this.heartCount,
      streakCount: streakCount ?? this.streakCount,
      totalXp: totalXp ?? this.totalXp,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}

@Riverpod(keepAlive: true)
class UserStore extends _$UserStore {
  @override
  UserModel build() {
    // Attempt local load asynchronously upon initialization
    Future.microtask(() => initFromLocal());
    return const UserModel();
  }

  /// Loads cached ground truth from local SQLite on startup or offline fallback
  Future<void> initFromLocal() async {
    try {
      final repo = ProgressRepository();
      final localXpStr = await repo.getLocalState('total_xp');
      final localStreakStr = await repo.getLocalState('streak_count');
      final localHeartsStr = await repo.getLocalState('current_hearts');

      final localXp = localXpStr != null ? int.tryParse(localXpStr) : null;
      final localStreak = localStreakStr != null ? int.tryParse(localStreakStr) : null;
      final localHearts = localHeartsStr != null ? int.tryParse(localHeartsStr) : null;

      state = state.copyWith(
        totalXp: (localXp != null && localXp > state.totalXp) ? localXp : state.totalXp,
        streakCount: (localStreak != null && localStreak > state.streakCount) ? localStreak : state.streakCount,
        heartCount: localHearts ?? state.heartCount,
      );
    } catch (e) {
      // Local DB read error fallback
    }
  }

  Future<void> incrementStreak() async {
    final newValue = state.streakCount + 1;
    state = state.copyWith(streakCount: newValue);
    try {
      await ProgressRepository().saveLocalState('streak_count', newValue.toString());
    } catch (_) {}
    await _syncToSupabase({'streak_count': newValue});
  }

  Future<void> updateStreak(int streak) async {
    state = state.copyWith(streakCount: streak);
    try {
      await ProgressRepository().saveLocalState('streak_count', streak.toString());
    } catch (_) {}
    await _syncToSupabase({'streak_count': streak});
  }

  Future<void> addXp(int xp) async {
    // Security check: Ignore negative or 0 XP calls
    if (xp <= 0) return;
    // Exploit barrier: Cap single reward transaction to 1500 XP
    final validatedXp = xp > 1500 ? 1500 : xp;
    final newValue = state.totalXp + validatedXp;
    state = state.copyWith(totalXp: newValue);

    // 1. Persist immediately to SQLite ground truth (100% offline-proof)
    try {
      await ProgressRepository().saveLocalState('total_xp', newValue.toString());
    } catch (_) {}

    // 2. Sync to Supabase cloud
    await _syncToSupabase({'total_xp': newValue});
  }

  Future<void> useHeart() async {
    if (state.heartCount > 0) {
      final newValue = state.heartCount - 1;
      state = state.copyWith(heartCount: newValue);
      await _syncToSupabase({'current_hearts': newValue});
    }
  }

  Future<void> updateHearts(int count) async {
    state = state.copyWith(heartCount: count);
    try {
      await ProgressRepository().saveLocalState('current_hearts', count.toString());
    } catch (_) {}
    await _syncToSupabase({'current_hearts': count});
  }

  Future<void> updateUsername(String username) async {
    state = state.copyWith(username: username);
    await _syncToSupabase({'username': username});
  }

  Future<void> resetHearts() async {
    state = state.copyWith(heartCount: 5);
    await _syncToSupabase({'current_hearts': 5});
  }

  Future<void> updateProfile({String? username, String? avatarId, String? selectedDistrict}) async {
    state = state.copyWith(
      username: username ?? state.username,
      avatarId: avatarId ?? state.avatarId,
      selectedDistrict: selectedDistrict ?? state.selectedDistrict,
    );
    
    final updates = <String, dynamic>{};
    if (username != null) updates['username'] = username;
    if (avatarId != null) updates['avatar_id'] = avatarId;
    if (selectedDistrict != null) updates['district'] = selectedDistrict;
    
    if (updates.isNotEmpty) {
      await _syncToSupabase(updates);
    }
  }

  void setProfile({
    required String username,
    required String avatarId,
    required String selectedDistrict,
    int? streakCount,
    int? totalXp,
    int? heartCount,
  }) {
    // This is called on load, so we don't sync back to avoid infinite loops
    state = state.copyWith(
      username: username,
      avatarId: avatarId,
      selectedDistrict: selectedDistrict,
      streakCount: streakCount ?? state.streakCount,
      totalXp: totalXp ?? state.totalXp,
      heartCount: heartCount ?? state.heartCount,
    );
  }

  Future<void> refreshProfile() async {
    // 1. Ensure local SQLite state is loaded first (vital for offline startup)
    await initFromLocal();

    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        final cloudXp = (response['total_xp'] as num?)?.toInt() ?? 0;
        final cloudStreak = (response['streak_count'] as num?)?.toInt() ?? 0;
        final cloudHearts = (response['current_hearts'] as num?)?.toInt();

        // High-water mark resolution: If offline earnings exist locally, preserve them!
        final resolvedXp = state.totalXp > cloudXp ? state.totalXp : cloudXp;
        final resolvedStreak = state.streakCount > cloudStreak ? state.streakCount : cloudStreak;

        // Local SQLite is ground-truth for hearts on this device. Fallback to cloud if first login.
        final repo = ProgressRepository();
        final localHeartsStr = await repo.getLocalState('current_hearts');
        final localHearts = localHeartsStr != null ? int.tryParse(localHeartsStr) : null;
        final resolvedHearts = localHearts ?? cloudHearts ?? state.heartCount;

        state = state.copyWith(
          username: response['username'] as String? ?? state.username,
          avatarId: response['avatar_id'] as String? ?? state.avatarId,
          selectedDistrict: response['district'] as String? ?? state.selectedDistrict,
          streakCount: resolvedStreak,
          totalXp: resolvedXp,
          heartCount: resolvedHearts,
        );

        // Update local SQLite with resolved values
        await repo.saveLocalState('total_xp', resolvedXp.toString());
        await repo.saveLocalState('streak_count', resolvedStreak.toString());
        await repo.saveLocalState('current_hearts', resolvedHearts.toString());

        // If local offline progress was ahead of cloud, sync upward to Supabase
        if (state.totalXp > cloudXp || state.streakCount > cloudStreak) {
          await _syncToSupabase({
            'total_xp': resolvedXp,
            'streak_count': resolvedStreak,
          });
        }

        if (response['weekly_test_level'] != null) {
          await repo.saveLocalState(
            'highest_unlocked_level',
            response['weekly_test_level'].toString(),
          );
        }
      }
    } catch (e) {
      // Offline fallback: State remains safely loaded from local SQLite
    }
  }

  Future<void> _syncToSupabase(Map<String, dynamic> updates) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;
      
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      await SupabaseConfig.client
          .from('profiles')
          .update(updates)
          .eq('id', userId);
    } catch (e) {
      // Cloud sync failed (offline mode); local SQLite maintains ground truth
    }
  }
}
