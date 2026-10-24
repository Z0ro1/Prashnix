# Duolingo Home Screen Package (Extracted from Official APK)

This folder contains a 1:1 pixel-perfect recreation of the **Duolingo Home / Learning Path Screen**, complete with all reverse-engineered assets, official fonts, vector animations, sound effects, and physical tactile animations.

---

## 📁 Package Directory Structure

```text
duolingo_extracted_screen/
├── duolingo_home_screen.dart        # Complete, drop-in Flutter screen matching the screenshot
├── theme/
│   ├── app_colors.dart              # Official extracted Duolingo color palette
│   └── app_text_styles.dart         # Extracted typography definitions (DuolingoSans & DIN Next)
├── components/
│   ├── duo_stats_bar.dart           # Top stats header (Flag pill, 🔥 Streak, 💎 Gems, ❤️ Hearts)
│   ├── duo_unit_header.dart         # Unit 1 green header card with guidebook action button
│   ├── duo_path_node.dart           # 3D tactile node buttons with checkmark, chest, or star
│   ├── duo_floating_tooltip.dart    # Floating "START +15 XP" tooltip with bobbing animation
│   ├── duo_pulsing_ring.dart        # Concentric breathing glow ring behind active star node
│   ├── duo_stepping_dots.dart       # Stepping stone connector dots along the S-curve
│   ├── duo_bottom_nav.dart          # 3-item bottom navigation bar (LEARN, LEAGUES, PROFILE)
│   └── duo_audio_service.dart       # Sound player using extracted APK MP3s & OGGs
├── assets/
│   ├── fonts/                       # 20 official Duolingo OTF/TTF fonts
│   │   ├── duolingosans_bold.otf
│   │   ├── duolingosans_medium.otf
│   │   ├── din_next_for_duolingo_bold.otf
│   │   └── ...
│   ├── audio/                       # 78 extracted audio effects
│   │   ├── star_chime.mp3           # Star level complete chime
│   │   ├── node_complete.mp3        # Node completion audio
│   │   ├── tap_token_press_a_27.mp3 # Tactile click sound
│   │   ├── gems_large_reward_v9.mp3 # Mystery chest reward audio
│   │   └── ...
│   ├── lottie/                      # 87 extracted vector animations
│   │   ├── path_duo_cheer.json
│   │   ├── streak_increased_flame.json
│   │   └── ...
│   └── icons/                       # Extracted SVGs (Learn, Leagues, Profile, Guidebook, Star, Check)
├── pubspec_snippet.yaml             # Asset declarations & dependencies to copy into pubspec.yaml
└── README.md                        # Documentation
```

---

## 🚀 How to Use in Any Flutter Project

### 1. Add Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  flutter:
    sdk: flutter
  audioplayers: ^6.1.1
  lottie: ^3.3.1
```

### 2. Register Assets & Fonts (`pubspec.yaml`)
Copy the contents of `pubspec_snippet.yaml` into your `pubspec.yaml`:
```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/audio/
    - assets/lottie/
    - assets/icons/

  fonts:
    - family: DuolingoSans
      fonts:
        - asset: assets/fonts/duolingosans_regular.otf
        - asset: assets/fonts/duolingosans_medium.otf
          weight: 500
        - asset: assets/fonts/duolingosans_bold.otf
          weight: 700

    - family: DINNext
      fonts:
        - asset: assets/fonts/din_next_for_duolingo.otf
        - asset: assets/fonts/din_next_for_duolingo_medium.otf
          weight: 500
        - asset: assets/fonts/din_next_for_duolingo_bold.otf
          weight: 700
```

### 3. Launch Screen in Your App
```dart
import 'package:flutter/material.dart';
import 'duolingo_home_screen.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DuolingoHomeScreen(),
  ));
}
```

---

## 🎨 Screen Features & Interactivity Included
* **Flag Pill (`🇪🇸 ▾`)**: Tap to open interactive Course Switcher modal (Spanish, French, Japanese).
* **Streak Counter (`🔥 16`)**: Tap to play classic streak flame sound and see streak status.
* **Gems Pill (`💎 565`)**: Tap to see gem balance and play reward chime.
* **Hearts Counter (`❤️ 5`)**: Tap to open hearts refill modal with Practice & Refill options.
* **Unit 1 Banner**: "Order Food & Drinks" with interactive Guidebook button.
* **Stepping Dots**: Exactly 3 and 2 grey stepping dots bridging nodes along the winding curve.
* **Nodes 1 & 2**: Yellow 3D tactile buttons with checkmarks (`✓`).
* **Node 3**: Yellow 3D tactile button with 3D mystery gift box (`🎁`) that opens animated reward dialog.
* **Node 4**: Active Emerald Green 3D star button with:
  * Floating `"START +15 XP"` tooltip with downward triangle arrow and gentle bobbing animation.
  * Concentric pulsating outer ring with smooth breathing animation.
  * Tactile button compression (translates down 4px on tap) with haptic feedback and `star_chime.mp3`.
* **Bottom Navigation Bar**: LEARN (green graduation cap), LEAGUES (grey shield), and PROFILE (grey avatar).
