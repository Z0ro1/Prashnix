import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../state/user_state.dart';
import '../../features/skill_tree/presentation/screens/skill_tree_screen.dart';
import '../../features/mistakes/presentation/screens/mistake_review_screen.dart';
import '../../features/quiz/presentation/screens/weekly_test_screen.dart';
import '../../features/gamification/presentation/screens/league_screen.dart';
import '../../features/profile/presentation/widgets/settings_profile_bottom_sheet.dart';
import '../theme/app_colors.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const SkillTreeScreen(), // Home / Path
    const MistakeReviewScreen(), // Mistakes
    const WeeklyTestScreen(), // Weekly Test
    const LeagueScreen(), // Streaks -> League
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseConfig.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
            
        if (response != null) {
          ref.read(userStoreProvider.notifier).setProfile(
            username: response['username'] ?? '',
            avatarId: response['avatar_id'] ?? '',
            selectedDistrict: response['district'] ?? 'Beginner District',
            streakCount: response['streak_count'] ?? 0,
            totalXp: response['total_xp'] ?? 0,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 4) {
              SettingsProfileBottomSheet.show(context);
              return;
            }
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardSurface,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          items: [
            _buildNavItem('assets/icons/home.svg', 0),
            _buildNavItem('assets/icons/Mistake questions.svg', 1),
            _buildNavItem('assets/icons/weekly test.svg', 2),
            _buildNavItem('assets/icons/Streaks.svg', 3),
            _buildNavItem('assets/icons/setting and profile.svg', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String assetPath, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMint.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: AppColors.primaryMint.withOpacity(0.3), width: 2) : Border.all(color: Colors.transparent, width: 2),
        ),
        child: Opacity(
          opacity: isSelected ? 1.0 : 0.5,
          child: SvgPicture.asset(
            assetPath,
            width: 32,
            height: 32,
          ),
        ),
      ),
      label: '',
    );
  }
}
