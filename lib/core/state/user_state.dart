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

@riverpod
class UserStore extends _$UserStore {
  @override
  UserModel build() {
    return const UserModel();
  }

  Future<void> incrementStreak() async {
    final newValue = state.streakCount + 1;
    state = state.copyWith(streakCount: newValue);
    await _syncToSupabase({'streak_count': newValue});
  }

  Future<void> addXp(int xp) async {
    final newValue = state.totalXp + xp;
    state = state.copyWith(totalXp: newValue);
    // You could also track weekly_xp here by reading it first, but for now we sync total_xp
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
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;

      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          username: response['username'] as String? ?? state.username,
          avatarId: response['avatar_id'] as String? ?? state.avatarId,
          selectedDistrict: response['district'] as String? ?? state.selectedDistrict,
          streakCount: (response['streak_count'] as num?)?.toInt() ?? state.streakCount,
          totalXp: (response['total_xp'] as num?)?.toInt() ?? state.totalXp,
          heartCount: (response['current_hearts'] as num?)?.toInt() ?? state.heartCount,
        );

        if (response['weekly_test_level'] != null) {
          await ProgressRepository().saveLocalState(
            'highest_unlocked_level',
            response['weekly_test_level'].toString(),
          );
        }
      }
    } catch (e) {
      print('Failed to refresh user profile from Supabase: $e');
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
      print('Failed to sync user profile to Supabase: $e');
    }
  }
}
