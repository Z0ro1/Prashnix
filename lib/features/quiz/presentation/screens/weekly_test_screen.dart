import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/state/user_state.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../providers/quiz_provider.dart';
import 'quiz_screen.dart';

class WeeklyTestScreen extends ConsumerStatefulWidget {
  const WeeklyTestScreen({super.key});

  @override
  ConsumerState<WeeklyTestScreen> createState() => _WeeklyTestScreenState();
}

class _WeeklyTestScreenState extends ConsumerState<WeeklyTestScreen> {
  late Timer _timer;
  Duration _timeLeft = const Duration();
  String _selectedExamType = 'MPSC Rajyaseva';
  bool _isReminderSet = false;

  final List<String> _examTypes = [
    'MPSC Rajyaseva',
    'Combine Group B & C',
    'Police Bharti',
    'Talathi Bharti'
  ];

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    // Next Sunday 12:00 PM
    var nextSunday = now.add(Duration(days: DateTime.sunday - now.weekday));
    nextSunday = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 12, 0, 0);
    
    if (now.isAfter(nextSunday)) {
      nextSunday = nextSunday.add(const Duration(days: 7));
    }
    
    if (mounted) {
      setState(() {
        _timeLeft = nextSunday.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    String days = d.inDays.toString().padLeft(2, '0');
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0F1115) : AppColors.backgroundLight;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;
    final cardBorder = isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.borderLight;
    final dividerColor = isDark ? Colors.white24 : AppColors.borderLight;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final textMuted = isDark ? Colors.white70 : AppColors.textSecondary;
    final textSubtle = isDark ? Colors.white54 : AppColors.textMuted;
    final refreshBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final timerBg = isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFFFF9E6);
    final timerTextColor = isDark ? AppColors.canaryYellow : const Color(0xFFB38600);

    // Real variables representing no fake data
    final int lastWeekScore = 0;
    final int allTimeBest = 0;
    final String currentLeader = "---";
    final int leaderScore = 0;

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.wait([
            ref.read(userStoreProvider.notifier).refreshProfile(),
            SyncService().pullProgress(),
          ]);
          _calculateTimeLeft();
          if (mounted) setState(() {});
        },
        color: isDark ? AppColors.canaryYellow : AppColors.primaryGreen,
        backgroundColor: refreshBg,
        displacement: 60,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // Header / Timer Section
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.canaryYellow.withValues(alpha: isDark ? 0.15 : 0.25),
                      bgColor,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.canaryYellow.withValues(alpha: isDark ? 0.2 : 0.35),
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.canaryYellow.withValues(alpha: isDark ? 0.1 : 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.canaryYellow.withValues(alpha: isDark ? 0.5 : 0.7),
                            ),
                          ),
                          child: Text(
                            'WEEKLY CHAMPIONSHIP',
                            style: AppTextStyles.label.copyWith(
                              color: isDark ? AppColors.canaryYellow : const Color(0xFF996B00),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ).animate().fade().slideY(begin: -0.2),
                        
                        // Reminder Bell
                        GestureDetector(
                          onTap: () {
                            setState(() => _isReminderSet = !_isReminderSet);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isReminderSet ? 'Reminder Set!' : 'Reminder Cancelled'),
                                backgroundColor: AppColors.primaryMint,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isReminderSet
                                  ? AppColors.canaryYellow.withValues(alpha: isDark ? 0.2 : 0.25)
                                  : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                              border: Border.all(
                                color: _isReminderSet
                                    ? AppColors.canaryYellow
                                    : (isDark ? Colors.white24 : AppColors.borderLight),
                              ),
                            ),
                            child: Icon(
                              _isReminderSet ? Icons.notifications_active : Icons.notifications_none,
                              color: _isReminderSet
                                  ? (isDark ? AppColors.canaryYellow : const Color(0xFFB38600))
                                  : textSubtle,
                            ),
                          ),
                        ).animate().fade(),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Next Test Closes In:',
                      style: AppTextStyles.body.copyWith(color: textMuted),
                    ).animate().fade(delay: 100.ms),
                    const SizedBox(height: 12),
                    // Glowing Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: timerBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.canaryYellow.withValues(alpha: isDark ? 0.3 : 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.canaryYellow.withValues(alpha: isDark ? 0.1 : 0.2),
                            blurRadius: 20,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Text(
                        _formatDuration(_timeLeft),
                        style: AppTextStyles.h1.copyWith(
                          color: timerTextColor, 
                          fontSize: 36,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1,1), end: const Offset(1.02, 1.02), duration: 1.seconds),
                  ],
                ),
              ),
            ),
            
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Exam Type Selection
                    Text('Select Paper Type', style: AppTextStyles.h3.copyWith(color: textColor)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _examTypes.length,
                        itemBuilder: (context, index) {
                          final type = _examTypes[index];
                          final isSelected = type == _selectedExamType;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedExamType = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? (isDark ? AppColors.primaryMint.withValues(alpha: 0.2) : AppColors.primaryMint.withValues(alpha: 0.15))
                                    : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF4F5F7)),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isSelected 
                                      ? AppColors.primaryMint 
                                      : (isDark ? Colors.white12 : AppColors.borderLight),
                                  width: isSelected ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                type,
                                style: AppTextStyles.label.copyWith(
                                  color: isSelected 
                                      ? (isDark ? Colors.white : AppColors.primaryGreenDark)
                                      : textSubtle,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ).animate().fade(delay: (200 + (index * 50)).ms).slideX();
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    // High Score Glass Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: cardBorder),
                            boxShadow: isDark ? null : AppColors.softCardShadow,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Text('Last Week', style: AppTextStyles.label.copyWith(color: textSubtle)),
                                  const SizedBox(height: 8),
                                  Text(lastWeekScore > 0 ? '$lastWeekScore/100' : '---', style: AppTextStyles.h2.copyWith(color: textColor)),
                                ],
                              ),
                              Container(width: 1, height: 40, color: dividerColor),
                              Column(
                                children: [
                                  Text('All-Time Best', style: AppTextStyles.label.copyWith(color: textSubtle)),
                                  const SizedBox(height: 8),
                                  Text(allTimeBest > 0 ? '$allTimeBest/100' : '---', style: AppTextStyles.h2.copyWith(color: isDark ? AppColors.primaryMint : AppColors.primaryGreenDark)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 16),

                    // Leaderboard Teaser
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.primaryMint.withValues(alpha: 0.1) : AppColors.primaryMint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryMint.withValues(alpha: isDark ? 0.3 : 0.4)),
                        boxShadow: isDark ? null : AppColors.softCardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              color: AppColors.primaryMint.withValues(alpha: isDark ? 0.2 : 0.25),
                            ),
                            child: const Text('👑', style: TextStyle(fontSize: 24)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Current Leader: $currentLeader', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                                Text('Score: $leaderScore/100. Can you beat them?', style: AppTextStyles.label.copyWith(color: textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),
                    
                    // Rules & Specs
                    Text('Test Specifications', style: AppTextStyles.h3.copyWith(color: textColor)).animate().fade(delay: 500.ms),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorder),
                        boxShadow: isDark ? null : AppColors.softCardShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SpecItem(icon: Icons.list_alt, value: '100', label: 'Questions', isDark: isDark),
                          Container(width: 1, height: 40, color: dividerColor),
                          _SpecItem(icon: Icons.timer, value: '90', label: 'Minutes', isDark: isDark),
                          Container(width: 1, height: 40, color: dividerColor),
                          _SpecItem(icon: Icons.warning_amber_rounded, value: '-0.25', label: 'Negative', isDark: isDark),
                        ],
                      ),
                    ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 32),
                    
                    // Reward Preview
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: themeGradient(isDark),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.canaryYellow.withValues(alpha: isDark ? 0.3 : 0.45),
                        ),
                        boxShadow: isDark ? null : AppColors.softCardShadow,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Completion Rewards',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppColors.canaryYellow : const Color(0xFFB38600),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(children: [const Text('💎 ', style: TextStyle(fontSize: 18)), Text('+500 XP', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.bold))]),
                              Container(width: 1, height: 20, color: dividerColor),
                              Row(children: [const Text('❤️ ', style: TextStyle(fontSize: 18)), Text('Full Reset', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.bold))]),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 700.ms).slideY(begin: 0.1),
                    
                    const SizedBox(height: 48),
                    
                    // Start Button
                    GestureDetector(
                      onTap: () {
                        ref.read(quizProvider.notifier).loadQuestionsForNode('weekly_test_$_selectedExamType');
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const QuizScreen()),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMint,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryMint.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 5))
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'START OFFICIAL MOCK TEST',
                            style: AppTextStyles.h2.copyWith(color: AppColors.deepTealNavy, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 800.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 16),

                    // Review Last Week Secondary Button
                    GestureDetector(
                      onTap: () {
                        if (lastWeekScore == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No previous test found to review.', style: AppTextStyles.body.copyWith(color: Colors.white)),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardBorder),
                          boxShadow: isDark ? null : AppColors.softCardShadow,
                        ),
                        child: Center(
                          child: Text(
                            'Review Last Week\'s Paper',
                            style: AppTextStyles.h3.copyWith(color: textMuted),
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 900.ms),

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient themeGradient(bool isDark) {
    return LinearGradient(
      colors: [
        AppColors.canaryYellow.withValues(alpha: isDark ? 0.2 : 0.2),
        isDark ? Colors.transparent : Colors.white,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool isDark;

  const _SpecItem({
    required this.icon,
    required this.value,
    required this.label,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primaryMint, size: 28),
        const SizedBox(height: 12),
        Text(value, style: AppTextStyles.h2.copyWith(color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: isDark ? Colors.white54 : AppColors.textSecondary)),
      ],
    );
  }
}
