import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  void incrementStreak() {
    state = state.copyWith(streakCount: state.streakCount + 1);
  }

  void addXp(int xp) {
    state = state.copyWith(totalXp: state.totalXp + xp);
  }

  void useHeart() {
    if (state.heartCount > 0) {
      state = state.copyWith(heartCount: state.heartCount - 1);
    }
  }

  void updateHearts(int count) {
    state = state.copyWith(heartCount: count);
  }

  void updateUsername(String username) {
    state = state.copyWith(username: username);
  }

  void resetHearts() {
    state = state.copyWith(heartCount: 5);
  }

  void updateProfile({String? username, String? avatarId, String? selectedDistrict}) {
    state = state.copyWith(
      username: username ?? state.username,
      avatarId: avatarId ?? state.avatarId,
      selectedDistrict: selectedDistrict ?? state.selectedDistrict,
    );
  }

  void setProfile({
    required String username,
    required String avatarId,
    required String selectedDistrict,
    int? streakCount,
    int? totalXp,
  }) {
    state = state.copyWith(
      username: username,
      avatarId: avatarId,
      selectedDistrict: selectedDistrict,
      streakCount: streakCount ?? state.streakCount,
      totalXp: totalXp ?? state.totalXp,
    );
  }
}
