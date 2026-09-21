import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/state/user_state.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(user.username.isNotEmpty ? user.username : 'Guest', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
        elevation: 0,
        foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildInstagramHeader(context, user),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.skyBlue,
                    indicatorWeight: 3,
                    labelColor: AppColors.skyBlue,
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
            children: [
              _buildStreakCalendarTab(context),
              _buildBookmarksTab(context),
              _buildLockedFeatureTab(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstagramHeader(BuildContext context, UserModel user) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar
          Column(
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.featherGreen, width: 4),
                ),
                child: CircleAvatar(
                  backgroundColor: AppColors.surfaceLight,
                  backgroundImage: user.avatarId.isNotEmpty 
                      ? AssetImage('assets/avatars/${user.avatarId}') 
                      : null,
                  child: user.avatarId.isEmpty 
                    ? Text(
                        user.username.isNotEmpty ? user.username[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                      )
                    : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.username.isNotEmpty ? user.username : 'Guest',
                style: AppTypography.titleSemiBold.copyWith(color: textColor, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Stats Row
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn("12", "Rank", Icons.emoji_events_rounded, AppColors.canaryYellow, textColor, mutedColor),
                _buildStatColumn("${user.streakCount}", "Streak", Icons.local_fire_department_rounded, AppColors.foxOrange, textColor, mutedColor),
                _buildStatColumn("${user.totalXp}", "Total XP", Icons.bolt_rounded, AppColors.skyBlue, textColor, mutedColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color iconColor, Color textColor, Color mutedColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppTypography.titleSemiBold.copyWith(
                color: textColor,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.subtextCaption.copyWith(
            color: mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCalendarTab(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Banner
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.ac_unit_rounded, color: AppColors.skyBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Streak Freeze", style: AppTypography.titleSemiBold.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 16)),
                      Text("2 Freezes Available", style: AppTypography.subtextCaption.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ),
                ),
                CustomButton(
                  text: "EQUIP",
                  variant: ButtonVariant.outline,
                  onPressed: () {},
                )
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Calendar
          AppCard(
            padding: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AppTypography.titleSemiBold.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                leftChevronIcon: Icon(Icons.chevron_left_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                rightChevronIcon: Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: TextStyle(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontWeight: FontWeight.bold),
                weekendTextStyle: TextStyle(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight, fontWeight: FontWeight.bold),
                todayDecoration: const BoxDecoration(
                  color: AppColors.canaryYellow,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.foxOrange,
                  shape: BoxShape.circle,
                ),
              ),
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksTab(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.featherGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Grammar",
                      style: AppTypography.subtextCaption.copyWith(color: AppColors.featherGreen, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const Icon(Icons.bookmark_rounded, color: AppColors.skyBlue),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "How do you conjugate 'ir' in the present tense?",
                style: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: "PRACTICE NOW",
                onPressed: () {},
                elevation: 2,
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildLockedFeatureTab(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: AppCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 80, color: AppColors.borderLight),
              const SizedBox(height: 24),
              Text(
                "Coming Soon!",
                style: AppTypography.titleSemiBold.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, fontSize: 24),
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
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
