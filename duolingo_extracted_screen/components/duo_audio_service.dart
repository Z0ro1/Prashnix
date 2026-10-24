import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Audio service utilizing authentic sound effects extracted from the Duolingo APK.
class DuoAudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playSound(String soundName) async {
    try {
      HapticFeedback.lightImpact();
      await _player.stop();
      await _player.play(AssetSource('audio/$soundName'));
    } catch (_) {
      // Audio playback fallback gracefully ignored if asset path is unconfigured
    }
  }

  /// Node click sound
  static Future<void> playTap() => playSound('tap_token_press_a_27.mp3');

  /// Star completion / active node chime
  static Future<void> playStarChime() => playSound('star_chime.mp3');

  /// Node completed chime
  static Future<void> playNodeComplete() => playSound('node_complete.mp3');

  /// Gem / Chest reward audio
  static Future<void> playGemsReward() => playSound('gems_large_reward_v9.mp3');

  /// Streak flame sound
  static Future<void> playStreakFlame() => playSound('streak_classic_flame.mp3');
}
