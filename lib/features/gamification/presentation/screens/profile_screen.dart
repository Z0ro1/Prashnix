import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/state/user_state.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userStoreProvider);
    final String displayName = user.username.isNotEmpty ? user.username : 'Guest';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(displayName, style: AppTypography.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.edit_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ).animate().fade(),
          IconButton(
            icon: Icon(Icons.settings_rounded, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ).animate().fade().rotate(duration: 400.ms),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            HapticFeedback.mediumImpact();
            await Future.wait([
              ref.read(userStoreProvider.notifier).refreshProfile(),
              SyncService().pullProgress(),
            ]);
            if (mounted) setState(() {});
          },
          color: AppColors.primaryGreen,
          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          displacement: 40,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: _buildHeader(context, user),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverAppBarDelegate(
                    bgColor,
                    TabBar(
                      controller: _tabController,
                      indicatorColor: AppColors.primaryGreen,
                      indicatorWeight: 4,
                      dividerColor: isDark ? AppColors.borderDark : AppColors.borderLight,
                      labelColor: AppColors.primaryGreenDark,
                      unselectedLabelColor: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      tabs: const [
                        Tab(icon: Icon(Icons.local_fire_department_rounded, size: 28)),
                        Tab(icon: Icon(Icons.bookmark_rounded, size: 28)),
                        Tab(icon: Icon(Icons.lock_rounded, size: 28)),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildStreakCalendarTab(context).animate().fade().slideX(begin: 0.1),
                _buildBookmarksTab(context).animate().fade().slideX(begin: 0.1),
                _buildLockedFeatureTab(context).animate().fade().slideX(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Clean Avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppColors.softCardShadow,
              ),
              child: CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                backgroundImage: user.avatarId.isNotEmpty 
                    ? AssetImage('assets/avatars/${user.avatarId}') 
                    : null,
                child: user.avatarId.isEmpty 
                  ? Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : 'G',
                      style: AppTypography.headlineLarge.copyWith(color: Colors.white),
                    )
                  : null,
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
            
            const SizedBox(width: 24),
            
            // Stats
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn("-", "League", Icons.emoji_events_rounded, AppColors.waterBlue),
                  Container(width: 1, height: 40, color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
                  _buildStatColumn("${user.streakCount}", "Streak", Icons.local_fire_department_rounded, AppColors.stepOrange),
                  Container(width: 1, height: 40, color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
                  _buildStatColumn("${user.totalXp}", "Total XP", Icons.bolt_rounded, AppColors.primaryGreen),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.2);
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.headlineMedium.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
        ),
      ],
    );
  }

  Widget _buildStreakCalendarTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Streak Freeze Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.waterBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.waterBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.waterBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ac_unit_rounded, color: AppColors.waterBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Streak Freeze", style: AppTypography.headlineSmall.copyWith(color: textColor)),
                      const SizedBox(height: 4),
                      Text("2 Freezes Available", style: AppTypography.labelMedium.copyWith(color: AppColors.waterBlue)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.waterBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: Text("EQUIP", style: AppTypography.labelLarge.copyWith(color: Colors.white)),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Calendar
          AppCard(
            padding: const EdgeInsets.all(20),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTypography.headlineSmall.copyWith(color: textColor),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: mutedColor),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: mutedColor),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AppTypography.labelMedium.copyWith(color: mutedColor),
                weekendStyle: AppTypography.labelMedium.copyWith(color: mutedColor),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: AppTypography.bodyMedium.copyWith(color: textColor),
                weekendTextStyle: AppTypography.bodyMedium.copyWith(color: mutedColor),
                outsideTextStyle: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                todayDecoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.stepOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.stepOrange.withValues(alpha: 0.4), blurRadius: 10)
                  ]
                ),
              ),
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
            ),
            child: Icon(Icons.bookmark_border_rounded, size: 64, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            "No saved questions",
            style: AppTypography.headlineMedium.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            "Questions you save will appear here.",
            style: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedFeatureTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: AppCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 80, color: isDark ? AppColors.borderDark : AppColors.borderLight)
                  .animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
              const SizedBox(height: 24),
              Text(
                "Coming Soon!",
                style: AppTypography.headlineMedium.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "This feature will unlock in the next version!",
                style: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.bgColor, this._tabBar);

  final Color bgColor;
  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: bgColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
