import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/state/user_state.dart';
import '../../../../core/widgets/app_card.dart';
import '../providers/streak_provider.dart';
import '../../domain/models/streak_model.dart';
import '../../domain/models/league_tier.dart';
import '../../../profile/presentation/screens/edit_profile_screen.dart';
import '../../../profile/presentation/screens/settings_screen.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../../../../core/models/question_model.dart';
import '../../../profile/presentation/providers/saved_questions_provider.dart';
import '../../../profile/presentation/widgets/subject_heatmap_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

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
                        Tab(icon: Icon(Icons.insights_rounded, size: 28)),
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
                const SubjectHeatmapWidget().animate().fade().slideX(begin: 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel user) {
    final leagueTier = LeagueTier.fromXp(user.totalXp);

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
                  _buildStatColumn(
                    leagueTier.name.replaceAll(' League', ''),
                    "League",
                    icon: leagueTier.icon,
                    iconColor: leagueTier.primaryColor,
                    imageAsset: leagueTier.badgeAsset,
                  ),
                  Container(width: 1, height: 40, color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
                  _buildStatColumn(
                    "${user.streakCount}",
                    "Streak",
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppColors.stepOrange,
                  ),
                  Container(width: 1, height: 40, color: Theme.of(context).brightness == Brightness.dark ? AppColors.borderDark : AppColors.borderLight),
                  _buildStatColumn(
                    "${user.totalXp}",
                    "Total XP",
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.primaryGreen,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fade().slideY(begin: 0.2);
  }

  Widget _buildStatColumn(
    String value,
    String label, {
    required IconData icon,
    required Color iconColor,
    String? imageAsset,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageAsset != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Image.asset(
                      imageAsset,
                      width: 20,
                      height: 20,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(icon, color: iconColor, size: 18),
                    ),
                  )
                else ...[
                  Icon(icon, color: iconColor, size: 18),
                  const SizedBox(width: 4),
                ],
                Text(
                  value,
                  style: AppTypography.headlineMedium.copyWith(color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ),
        ],
      ),
    );
  }

  String _dayToKey(DateTime day) {
    return '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  Widget _buildStreakCalendarTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final streak = ref.watch(streakProvider);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Streak Overview Metrics Row
          _buildStreakMetricsRow(streak, isDark, textColor, mutedColor),
          const SizedBox(height: 16),

          // 2. Streak Freeze Protection Card
          _buildFreezeCard(streak, isDark, textColor),
          const SizedBox(height: 20),
          
          // 3. Interactive Streak Calendar Card
          _buildStreakCalendar(streak, isDark, textColor, mutedColor),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStreakMetricsRow(StreakInfo streak, bool isDark, Color textColor, Color mutedColor) {
    final practicedToday = streak.isPracticedOn(_dayToKey(DateTime.now()));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Current Streak
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    '${streak.currentStreak}',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.stepOrange,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Current Streak', style: AppTypography.labelMedium.copyWith(color: mutedColor)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: practicedToday
                      ? AppColors.primaryGreen.withValues(alpha: 0.15)
                      : AppColors.stepOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  practicedToday ? 'Active Today' : 'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: practicedToday ? AppColors.primaryGreenDark : AppColors.stepOrange,
                  ),
                ),
              ),
            ],
          ),
          Container(width: 1, height: 50, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          // Longest Streak
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    '${streak.longestStreak}',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.canaryYellow,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Best Record', style: AppTypography.labelMedium.copyWith(color: mutedColor)),
              const SizedBox(height: 6),
              Text(
                'All-Time',
                style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(width: 1, height: 50, color: isDark ? AppColors.borderDark : AppColors.borderLight),
          // Total Active Days
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text(
                    '${streak.totalActiveDays}',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.primaryGreenDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Total Active', style: AppTypography.labelMedium.copyWith(color: mutedColor)),
              const SizedBox(height: 6),
              Text(
                'Days Practiced',
                style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFreezeCard(StreakInfo streak, bool isDark, Color textColor) {
    final freezes = streak.streakFreezes;
    final isFull = freezes >= 2;

    return Container(
      padding: const EdgeInsets.all(18),
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
            child: const Icon(Icons.ac_unit_rounded, color: AppColors.waterBlue, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Streak Freeze', style: AppTypography.headlineSmall.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  '$freezes / 2 Freezes Equipped',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.waterBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isFull ? AppColors.waterBlue.withValues(alpha: 0.4) : AppColors.waterBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              if (isFull) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Streak Freezes are full (2/2 equipped)! ❄️'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                await ref.read(streakProvider.notifier).equipOrRefillFreeze();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('+1 Streak Freeze Equipped! ❄️'),
                      backgroundColor: AppColors.waterBlue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: Text(
              isFull ? 'EQUIPPED' : 'REFILL (+1)',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStreakCalendar(StreakInfo streak, bool isDark, Color textColor, Color mutedColor) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Streak Calendar', style: AppTypography.headlineSmall.copyWith(color: textColor, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  _buildLegendIndicator('🔥', 'Practice', mutedColor),
                  const SizedBox(width: 12),
                  _buildLegendIndicator('❄️', 'Freeze', mutedColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: AppTypography.headlineSmall.copyWith(color: textColor, fontWeight: FontWeight.bold),
              leftChevronIcon: Icon(Icons.chevron_left_rounded, color: mutedColor),
              rightChevronIcon: Icon(Icons.chevron_right_rounded, color: mutedColor),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: AppTypography.labelMedium.copyWith(color: mutedColor, fontWeight: FontWeight.bold),
              weekendStyle: AppTypography.labelMedium.copyWith(color: mutedColor, fontWeight: FontWeight.bold),
            ),
            calendarStyle: CalendarStyle(
              defaultTextStyle: AppTypography.bodyMedium.copyWith(color: textColor),
              weekendTextStyle: AppTypography.bodyMedium.copyWith(color: mutedColor),
              outsideTextStyle: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final key = _dayToKey(day);
                if (streak.isPracticedOn(key)) {
                  return _buildStreakDayTile(day, isDark, isToday: false);
                } else if (streak.isFrozenOn(key)) {
                  return _buildFrozenDayTile(day, isDark);
                }
                return null;
              },
              todayBuilder: (context, day, focusedDay) {
                final key = _dayToKey(day);
                if (streak.isPracticedOn(key)) {
                  return _buildStreakDayTile(day, isDark, isToday: true);
                } else {
                  return _buildPendingTodayTile(day, isDark);
                }
              },
              selectedBuilder: (context, day, focusedDay) {
                return _buildSelectedDayTile(day, streak, isDark, textColor);
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _showDayDetails(selectedDay, streak);
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String emoji, String label, Color mutedColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: mutedColor, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildStreakDayTile(DateTime day, bool isDark, {bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF7A00), Color(0xFFFF9E00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: Colors.white, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF7A00).withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const Positioned(
            bottom: 2,
            child: Text('🔥', style: TextStyle(fontSize: 7)),
          ),
        ],
      ),
    );
  }

  Widget _buildFrozenDayTile(DateTime day, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.waterBlue.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            '${day.day}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const Positioned(
            bottom: 2,
            child: Text('❄️', style: TextStyle(fontSize: 7)),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTodayTile(DateTime day, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.stepOrange.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.stepOrange.withValues(alpha: 0.8),
          width: 1.8,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 1),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.stepOrange,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayTile(DateTime day, StreakInfo streak, bool isDark, Color textColor) {
    final key = _dayToKey(day);
    final isStreak = streak.isPracticedOn(key);
    final isFrozen = streak.isFrozenOn(key);

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isStreak ? AppColors.stepOrange : (isFrozen ? AppColors.waterBlue : AppColors.primaryGreen),
          width: 2.5,
        ),
      ),
      child: isStreak
          ? _buildStreakDayTile(day, isDark, isToday: isSameDay(day, DateTime.now()))
          : (isFrozen
              ? _buildFrozenDayTile(day, isDark)
              : Center(
                  child: Text(
                    '${day.day}',
                    style: AppTypography.bodyMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
    );
  }

  void _showDayDetails(DateTime day, StreakInfo streak) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final dayKey = _dayToKey(day);
    final isPracticed = streak.isPracticedOn(dayKey);
    final isFrozen = streak.isFrozenOn(dayKey);
    final record = streak.getActivityFor(dayKey);
    final isToday = isSameDay(day, DateTime.now());

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    isPracticed ? '🔥' : (isFrozen ? '❄️' : '📅'),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMMM d, y').format(day),
                          style: AppTypography.headlineSmall.copyWith(color: textColor, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isToday ? 'Today' : (isPracticed ? 'Streak Maintained' : (isFrozen ? 'Streak Freeze Protected' : 'Inactive Day')),
                          style: AppTypography.labelMedium.copyWith(
                            color: isPracticed ? AppColors.stepOrange : (isFrozen ? AppColors.waterBlue : mutedColor),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              const SizedBox(height: 12),
              if (isPracticed) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailItem(
                      icon: Icons.menu_book_rounded,
                      color: AppColors.primaryGreen,
                      value: '${record?.lessonsCompleted ?? 1}',
                      label: 'Lessons Done',
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                    _buildDetailItem(
                      icon: Icons.bolt_rounded,
                      color: AppColors.canaryYellow,
                      value: '+${record?.xpEarned ?? 30} XP',
                      label: 'XP Earned',
                      textColor: textColor,
                      mutedColor: mutedColor,
                    ),
                  ],
                ),
              ] else if (isFrozen) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.waterBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.waterBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.ac_unit_rounded, color: AppColors.waterBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'A Streak Freeze was consumed on this day to prevent your streak from breaking!',
                          style: AppTypography.bodySmall.copyWith(color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    isToday
                        ? "You haven't practiced yet today. Complete a lesson to keep your streak alive!"
                        : 'No lessons were completed on this day.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: mutedColor),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPracticed ? AppColors.stepOrange : AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: AppTypography.headlineSmall.copyWith(color: textColor, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: AppTypography.labelMedium.copyWith(color: mutedColor)),
      ],
    );
  }

  Widget _buildBookmarksTab(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final savedQuestionsAsync = ref.watch(savedQuestionsProvider);

    return savedQuestionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                    ),
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      size: 64,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                  const SizedBox(height: 24),
                  Text(
                    "No saved questions yet",
                    style: AppTypography.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the bookmark icon during any lesson to save questions here for quick revision.",
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: mutedColor, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          itemCount: questions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final question = questions[index];
            return _buildSavedQuestionCard(context, question, isDark, textColor, mutedColor);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      ),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Could not load saved questions',
                style: AppTypography.headlineSmall.copyWith(color: textColor),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.invalidate(savedQuestionsProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedQuestionCard(
    BuildContext context,
    QuestionModel question,
    bool isDark,
    Color textColor,
    Color mutedColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Subject, ID Badge, Bookmark Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      question.subjectTag,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primaryGreenDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(ClipboardData(text: question.displayCode));
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF1F2937),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                            content: Text('Question ID #${question.displayCode} copied!'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'ID: #${question.displayCode}',
                              style: AppTypography.labelSmall.copyWith(
                                color: mutedColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.copy_rounded, size: 11, color: mutedColor),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_rounded, color: AppColors.canaryYellow, size: 24),
                tooltip: 'Remove from bookmarks',
                onPressed: () {
                  if (question.id != null) {
                    HapticFeedback.mediumImpact();
                    ref.read(savedQuestionsProvider.notifier).toggleSaveStatus(question.id!);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF1F2937),
                        duration: const Duration(seconds: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        content: const Text('Question removed from bookmarks'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Question Text
          Text(
            question.questionText,
            style: AppTypography.headlineSmall.copyWith(
              color: textColor,
              height: 1.4,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Options A, B, C, D
          _buildOptionRow('A', question.optionA, question.correctOption == 'A', isDark),
          _buildOptionRow('B', question.optionB, question.correctOption == 'B', isDark),
          _buildOptionRow('C', question.optionC, question.correctOption == 'C', isDark),
          _buildOptionRow('D', question.optionD, question.correctOption == 'D', isDark),

          // Explanation Box (if available)
          if (question.explanation != null && question.explanation!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryMint.withValues(alpha: isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryMint.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryMint, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      question.explanation!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textPrimaryLight,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionRow(String label, String text, bool isCorrect, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCorrect
              ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.15 : 0.1)
              : (isDark ? AppColors.surfaceDimDark.withValues(alpha: 0.4) : AppColors.surfaceDimLight.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCorrect
                ? AppColors.primaryGreen.withValues(alpha: 0.5)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isCorrect ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label.',
              style: AppTypography.labelLarge.copyWith(
                color: isCorrect ? AppColors.primaryGreenDark : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: isCorrect ? AppColors.primaryGreenDark : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isCorrect)
              const Icon(Icons.check_circle_rounded, color: AppColors.primaryGreen, size: 18),
          ],
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
