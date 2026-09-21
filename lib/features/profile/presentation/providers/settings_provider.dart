import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/progress_repository.dart';

part 'settings_provider.g.dart';

class SettingsState {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool notificationsEnabled;
  final bool darkMode;

  const SettingsState({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.notificationsEnabled = true,
    this.darkMode = false,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  late final ProgressRepository _repo;

  @override
  SettingsState build() {
    _repo = ProgressRepository();
    _loadSettings();
    return const SettingsState(); // Initial synchronous default
  }

  Future<void> _loadSettings() async {
    final sound = await _repo.getLocalState('settings_sound') ?? '1';
    final haptics = await _repo.getLocalState('settings_haptics') ?? '1';
    final notifications = await _repo.getLocalState('settings_notifications') ?? '1';
    final dark = await _repo.getLocalState('settings_dark_mode') ?? '0';

    state = state.copyWith(
      soundEnabled: sound == '1',
      hapticsEnabled: haptics == '1',
      notificationsEnabled: notifications == '1',
      darkMode: dark == '1',
    );
  }

  Future<void> toggleSound(bool value) async {
    state = state.copyWith(soundEnabled: value);
    await _repo.saveLocalState('settings_sound', value ? '1' : '0');
  }

  Future<void> toggleHaptics(bool value) async {
    state = state.copyWith(hapticsEnabled: value);
    await _repo.saveLocalState('settings_haptics', value ? '1' : '0');
  }

  Future<void> toggleNotifications(bool value) async {
    state = state.copyWith(notificationsEnabled: value);
    await _repo.saveLocalState('settings_notifications', value ? '1' : '0');
  }

  Future<void> toggleDarkMode(bool value) async {
    state = state.copyWith(darkMode: value);
    await _repo.saveLocalState('settings_dark_mode', value ? '1' : '0');
  }
}
