import 'package:flutter/material.dart';
import 'components/duo_audio_service.dart';
import 'components/duo_bottom_nav.dart';
import 'components/duo_floating_tooltip.dart';
import 'components/duo_path_node.dart';
import 'components/duo_pulsing_ring.dart';
import 'components/duo_stats_bar.dart';
import 'components/duo_stepping_dots.dart';
import 'components/duo_unit_header.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

/// Pixel-perfect Duolingo Home / Learning Path Screen recreated directly from the APK.
class DuolingoHomeScreen extends StatefulWidget {
  const DuolingoHomeScreen({super.key});

  @override
  State<DuolingoHomeScreen> createState() => _DuolingoHomeScreenState();
}

class _DuolingoHomeScreenState extends State<DuolingoHomeScreen> {
  int _currentTabIndex = 0;
  int _streakDays = 16;
  int _gems = 565;
  int _hearts = 5;
  String _currentLanguage = '🇪🇸';

  void _showCourseSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Switch Course', style: TextStyle(
                fontFamily: AppTextStyles.duolingoSans,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              )),
              const SizedBox(height: 16),
              ListTile(
                leading: const Text('🇪🇸', style: TextStyle(fontSize: 28)),
                title: const Text('Spanish', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Unit 1 • Order Food & Drinks'),
                trailing: const Icon(Icons.check_circle_rounded, color: AppColors.green),
                onTap: () {
                  setState(() => _currentLanguage = '🇪🇸');
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Text('🇫🇷', style: TextStyle(fontSize: 28)),
                title: const Text('French', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Unit 1 • Greetings'),
                onTap: () {
                  setState(() => _currentLanguage = '🇫🇷');
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: const Text('🇯🇵', style: TextStyle(fontSize: 28)),
                title: const Text('Japanese', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hiragana 1 • Basics'),
                onTap: () {
                  setState(() => _currentLanguage = '🇯🇵');
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHeartsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❤️', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text('Hearts: $_hearts / 5', style: const TextStyle(
                fontFamily: AppTextStyles.duolingoSans,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              )),
              const SizedBox(height: 8),
              const Text(
                'Hearts refill over time, or you can practice mistakes to earn more hearts!',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() => _hearts = 5);
                  DuoAudioService.playStarChime();
                },
                child: const Text('REFILL ALL (100 💎)', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChestRewardModal() {
    DuoAudioService.playGemsReward();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎁', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('Mystery Chest Unlocked!', style: TextStyle(
              fontFamily: AppTextStyles.duolingoSans,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            )),
            const SizedBox(height: 8),
            const Text('You claimed +15 Gems & +15 XP bonus!', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                setState(() => _gems += 15);
                Navigator.of(ctx).pop();
              },
              child: const Text('CLAIM REWARD', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  void _onActiveNodeTap() {
    DuoAudioService.playStarChime();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.greenShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Text(
          'Starting Lesson: Order Food & Drinks (+15 XP)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: DuoStatsBar(
        streakDays: _streakDays,
        gems: _gems,
        hearts: _hearts,
        languageFlag: _currentLanguage,
        onFlagTap: _showCourseSelector,
        onHeartsTap: _showHeartsModal,
        onGemsTap: () {
          DuoAudioService.playGemsReward();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('You have $_gems Gems!', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
        onStreakTap: () {
          DuoAudioService.playStreakFlame();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('🔥 $_streakDays Day Streak! Keep practicing daily.', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Green Unit Header Card
            DuoUnitHeader(
              unitNumber: 1,
              title: 'Order Food & Drinks',
              description: 'Learn basic café vocabulary, greetings, and ordering essentials.',
              onGuidebookTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Guidebook: Unit 1 Café Vocabulary & Key Notes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. The Learning Path Nodes & Stepping Dots
            SizedBox(
              height: 520,
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // --- Stepping Dots between Node 1 (center) and Node 2 (offset right) ---
                  const Positioned(
                    top: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DuoSteppingDots(
                        count: 3,
                        startOffset: Offset(0, 0),
                        endOffset: Offset(45, 50),
                      ),
                    ),
                  ),

                  // --- Stepping Dots between Node 2 (offset right) and Node 3 (offset right) ---
                  const Positioned(
                    top: 215,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DuoSteppingDots(
                        count: 3,
                        startOffset: Offset(55, 0),
                        endOffset: Offset(55, 45),
                      ),
                    ),
                  ),

                  // --- Stepping Dots between Node 3 (offset right) and Node 4 (center) ---
                  const Positioned(
                    top: 345,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DuoSteppingDots(
                        count: 2,
                        startOffset: Offset(50, 0),
                        endOffset: Offset(10, 35),
                      ),
                    ),
                  ),

                  // --- Node 1: Completed Yellow Node (Center) ---
                  Positioned(
                    top: 0,
                    child: DuoPathNode(
                      type: DuoNodeType.completedCheck,
                      size: 80,
                      onTap: () => DuoAudioService.playNodeComplete(),
                    ),
                  ),

                  // --- Node 2: Completed Yellow Node (Offset Right +55px) ---
                  Positioned(
                    top: 130,
                    left: (MediaQuery.of(context).size.width / 2) - 40 + 55,
                    child: DuoPathNode(
                      type: DuoNodeType.completedCheck,
                      size: 80,
                      onTap: () => DuoAudioService.playNodeComplete(),
                    ),
                  ),

                  // --- Node 3: Milestone Yellow Gift Chest Node (Offset Right +55px) ---
                  Positioned(
                    top: 260,
                    left: (MediaQuery.of(context).size.width / 2) - 40 + 55,
                    child: DuoPathNode(
                      type: DuoNodeType.completedChest,
                      size: 80,
                      onTap: _showChestRewardModal,
                    ),
                  ),

                  // --- Node 4: Active Green Star Node with Floating Tooltip & Pulsing Ring ---
                  Positioned(
                    top: 370,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Floating Tooltip
                        const DuoFloatingTooltip(text: 'START +15 XP'),
                        const SizedBox(height: 6),
                        // Pulsing Ring & 3D Star Node
                        DuoPulsingRing(
                          size: 88,
                          child: DuoPathNode(
                            type: DuoNodeType.activeStar,
                            size: 84,
                            onTap: _onActiveNodeTap,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: DuoBottomNav(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
      ),
    );
  }
}
