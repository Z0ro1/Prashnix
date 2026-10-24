import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/constants/district_constants.dart';
import '../../../../core/state/user_state.dart';
import '../../data/repositories/cloud_sync_repository.dart';

part 'leaderboard_provider.g.dart';

enum LeaderboardCategory { xp, streak }

class LeaderboardState {
  final List<Map<String, dynamic>> ranks;
  final List<Map<String, dynamic>> streakRanks;
  final LeaderboardCategory category;
  final bool isDistrictMode;
  final String? selectedDistrict;
  final bool isLoading;
  final int? currentUserRank;
  final int? currentUserStreakRank;

  LeaderboardState({
    this.ranks = const [],
    this.streakRanks = const [],
    this.category = LeaderboardCategory.xp,
    this.isDistrictMode = true,
    this.selectedDistrict,
    this.isLoading = true,
    this.currentUserRank,
    this.currentUserStreakRank,
  });

  LeaderboardState copyWith({
    List<Map<String, dynamic>>? ranks,
    List<Map<String, dynamic>>? streakRanks,
    LeaderboardCategory? category,
    bool? isDistrictMode,
    String? selectedDistrict,
    bool? isLoading,
    int? currentUserRank,
    int? currentUserStreakRank,
  }) {
    return LeaderboardState(
      ranks: ranks ?? this.ranks,
      streakRanks: streakRanks ?? this.streakRanks,
      category: category ?? this.category,
      isDistrictMode: isDistrictMode ?? this.isDistrictMode,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      isLoading: isLoading ?? this.isLoading,
      currentUserRank: currentUserRank ?? this.currentUserRank,
      currentUserStreakRank: currentUserStreakRank ?? this.currentUserStreakRank,
    );
  }
}

@riverpod
class LeaderboardNotifier extends _$LeaderboardNotifier {
  late final CloudSyncRepository _repo;

  static const List<String> maharashtraDistricts = DistrictConstants.maharashtraDistricts;

  @override
  LeaderboardState build() {
    _repo = CloudSyncRepository();
    _initAndFetch();
    return LeaderboardState();
  }

  Future<void> _initAndFetch() async {
    // 1. First check local user state for chosen district
    final userState = ref.read(userStoreProvider);
    String initialDistrict = userState.selectedDistrict;
    
    if (initialDistrict.isEmpty || initialDistrict == 'Beginner District') {
      initialDistrict = 'Nashik';
    }

    // 2. Cross-check with Supabase profile
    final user = SupabaseConfig.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await SupabaseConfig.client
            .from('profiles')
            .select('district')
            .eq('id', user.id)
            .maybeSingle();
            
        if (profile != null && 
            profile['district'] != null && 
            (profile['district'] as String).trim().isNotEmpty) {
          initialDistrict = profile['district'] as String;
        }
      } catch (e) {
        // use local fallback
      }
    }
    
    state = state.copyWith(selectedDistrict: initialDistrict);
    await _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    state = state.copyWith(isLoading: true);
    List<Map<String, dynamic>> xpData = [];
    
    final district = state.selectedDistrict ?? 'Nashik';

    if (state.isDistrictMode) {
      xpData = await _repo.getDistrictLeaderboard(district, limit: 30);
    } else {
      xpData = await _repo.getGlobalLeaderboard(limit: 30);
    }

    // Sort descending by total_xp with secondary sort on weekly_xp
    xpData.sort((a, b) {
      final xpA = (a['total_xp'] as num?)?.toInt() ?? (a['weekly_xp'] as num?)?.toInt() ?? 0;
      final xpB = (b['total_xp'] as num?)?.toInt() ?? (b['weekly_xp'] as num?)?.toInt() ?? 0;
      return xpB.compareTo(xpA);
    });

    if (xpData.length > 30) {
      xpData = xpData.sublist(0, 30);
    }

    // Fetch Streak Leaderboard (All users, Top 10)
    List<Map<String, dynamic>> streakData = await _repo.getStreakLeaderboard(limit: 10);
    streakData.sort((a, b) {
      final sA = (a['streak_count'] as num?)?.toInt() ?? 0;
      final sB = (b['streak_count'] as num?)?.toInt() ?? 0;
      return sB.compareTo(sA);
    });

    if (streakData.length > 10) {
      streakData = streakData.sublist(0, 10);
    }

    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    final userState = ref.read(userStoreProvider);
    int? myXpRank;
    int? myStreakRank;

    if (currentUserId != null) {
      final idx = xpData.indexWhere((item) => item['id'] == currentUserId);
      if (idx != -1) {
        myXpRank = idx + 1;
      }
      final sIdx = streakData.indexWhere((item) => item['id'] == currentUserId);
      if (sIdx != -1) {
        myStreakRank = sIdx + 1;
      }
    }

    // Fallback for single/offline user
    if (streakData.isEmpty && userState.username.isNotEmpty) {
      streakData = [
        {
          'id': currentUserId ?? 'local_user',
          'username': userState.username,
          'avatar_id': userState.avatarId,
          'district': userState.selectedDistrict,
          'streak_count': userState.streakCount,
          'total_xp': userState.totalXp,
        }
      ];
      myStreakRank = 1;
    }

    state = state.copyWith(
      ranks: xpData,
      streakRanks: streakData,
      isLoading: false,
      currentUserRank: myXpRank,
      currentUserStreakRank: myStreakRank,
    );
  }

  void setCategory(LeaderboardCategory category) {
    if (state.category != category) {
      state = state.copyWith(category: category);
    }
  }

  void toggleMode(bool isDistrict) {
    if (state.isDistrictMode != isDistrict) {
      state = state.copyWith(isDistrictMode: isDistrict);
      _fetchLeaderboard();
    }
  }

  void changeDistrict(String newDistrict) {
    if (state.selectedDistrict != newDistrict) {
      state = state.copyWith(selectedDistrict: newDistrict);
      if (state.isDistrictMode) {
        _fetchLeaderboard();
      }
    }
  }

  Future<void> refresh() async {
    await _fetchLeaderboard();
  }
}
