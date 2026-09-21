import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../data/repositories/cloud_sync_repository.dart';

part 'leaderboard_provider.g.dart';

class LeaderboardState {
  final List<Map<String, dynamic>> ranks;
  final bool isDistrictMode;
  final bool isLoading;

  LeaderboardState({
    this.ranks = const [],
    this.isDistrictMode = true,
    this.isLoading = true,
  });

  LeaderboardState copyWith({
    List<Map<String, dynamic>>? ranks,
    bool? isDistrictMode,
    bool? isLoading,
  }) {
    return LeaderboardState(
      ranks: ranks ?? this.ranks,
      isDistrictMode: isDistrictMode ?? this.isDistrictMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class LeaderboardNotifier extends _$LeaderboardNotifier {
  late final CloudSyncRepository _repo;

  @override
  LeaderboardState build() {
    _repo = CloudSyncRepository();
    _fetchLeaderboard();
    return const LeaderboardState();
  }

  Future<void> _fetchLeaderboard() async {
    state = state.copyWith(isLoading: true);
    List<Map<String, dynamic>> data = [];
    
    // Get user district
    final user = SupabaseConfig.client.auth.currentUser;
    String district = 'Pune'; // Default fallback
    
    if (user != null) {
      try {
        final profile = await SupabaseConfig.client.from('profiles').select().eq('id', user.id).single();
        district = profile['district'] ?? 'Pune';
      } catch (e) {
        // ignore
      }
    }

    if (state.isDistrictMode) {
      data = await _repo.getDistrictLeaderboard(district);
    } else {
      data = await _repo.getGlobalLeaderboard();
    }

    // Mock data if Supabase returns empty (e.g. fresh DB)
    if (data.isEmpty) {
      data = _generateMockData(state.isDistrictMode ? district : 'Maharashtra');
    }

    state = state.copyWith(ranks: data, isLoading: false);
  }

  void toggleMode(bool isDistrict) {
    if (state.isDistrictMode != isDistrict) {
      state = state.copyWith(isDistrictMode: isDistrict);
      _fetchLeaderboard();
    }
  }

  Future<void> refresh() async {
    await _fetchLeaderboard();
  }

  List<Map<String, dynamic>> _generateMockData(String region) {
    return List.generate(20, (index) {
      return {
        'id': 'mock_$index',
        'username': 'candidate_$index',
        'avatar_id': index % 3 == 0 ? 'assets/avatars/zoro.jpg' : 'assets/avatars/luffy.jpg',
        'district': region,
        'weekly_xp': 5000 - (index * 100),
      };
    });
  }
}
