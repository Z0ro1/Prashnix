import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/state/user_state.dart';
import '../../../../core/models/weekly_test_model.dart';
import '../../../skill_tree/data/repositories/sync_service.dart';
import '../../data/repositories/weekly_test_repository.dart';
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
  String _selectedExamType = 'Police Bharti';
  bool _isReminderSet = false;
  bool _isLoadingTest = true;
  WeeklyTestModel? _activeTest;

  final List<String> _examTypes = [
    'Police Bharti',
    'MPSC Rajyaseva',
    'Combine Group B & C',
    'Talathi Bharti',
  ];

  @override
  void initState() {
    super.initState();
    _loadActiveTest();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeLeft();
    });
  }

  Future<void> _loadActiveTest() async {
    setState(() => _isLoadingTest = true);
    try {
      final repo = WeeklyTestRepository();
      final test = await repo.getActiveWeeklyTest(examType: _selectedExamType);
      if (mounted) {
        setState(() {
          _activeTest = test;
          _isLoadingTest = false;
        });
        _calculateTimeLeft();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingTest = false);
        _calculateTimeLeft();
      }
    }
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    DateTime targetTime;

    if (_activeTest != null) {
      final scheduled = _activeTest!.scheduledDate;
      // Default time is 12:00 PM if not specified
      int hour = 12;
      int minute = 0;
      if (_activeTest!.startTime != null && _activeTest!.startTime!.contains(':')) {
        try {
          final parts = _activeTest!.startTime!.split('T').last.split(':');
          hour = int.tryParse(parts[0]) ?? 12;
          minute = int.tryParse(parts[1]) ?? 0;
        } catch (_) {}
      }
      targetTime = DateTime(scheduled.year, scheduled.month, scheduled.day, hour, minute, 0);
    } else {
      // Default fallback: Next Sunday 12:00 PM
      final diff = (DateTime.sunday - now.weekday) % 7;
      final daysToAdd = diff == 0 ? 7 : diff;
      var nextSunday = now.add(Duration(days: daysToAdd));
      targetTime = DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 12, 0, 0);
      if (now.isAfter(targetTime)) {
        targetTime = targetTime.add(const Duration(days: 7));
      }
    }

    if (mounted) {
      setState(() {
        _timeLeft = targetTime.difference(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) {
      return "00d 00h 00m 00s";
    }
    String days = d.inDays.toString().padLeft(2, '0');
    String hours = (d.inHours % 24).toString().padLeft(2, '0');
    String minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "${days}d ${hours}h ${minutes}m ${seconds}s";
  }

  String _formatDateString(DateTime d) {
    const marathiMonths = [
      '', 'जानेवारी', 'फेब्रुवारी', 'मार्च', 'एप्रिल', 'मे', 'जून',
      'जुलै', 'ऑगस्ट', 'सप्टेंबर', 'ऑक्टोबर', 'नोव्हेंबर', 'डिसेंबर'
    ];
    const marathiDays = [
      '', 'सोमवार', 'मंगळवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'
    ];
    final dayName = marathiDays[d.weekday];
    final monthName = marathiMonths[d.month];
    return "$dayName, ${d.day} $monthName ${d.year}";
  }

  void _startTest() {
    HapticFeedback.heavyImpact();

    if (_activeTest != null && _activeTest!.questions.isNotEmpty) {
      // Load all 100 questions from Supabase weekly test directly
      ref.read(quizProvider.notifier).setQuestionsDirectly(
        _activeTest!.questions,
        nodeId: 'weekly_test_${_activeTest!.id}',
      );
    } else {
      // Fallback: Load 100 questions via node query
      ref.read(quizProvider.notifier).loadQuestionsForNode('weekly_test_$_selectedExamType');
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    ).then((_) {
      if (mounted) {
        ref.read(quizProvider.notifier).resetQuiz();
      }
    });
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

    final bool isLiveNow = _timeLeft.isNegative || _timeLeft.inSeconds == 0;
    final int questionCount = _activeTest?.questions.length ?? 100;
    final String testTitle = _activeTest?.title ?? 'महाराष्ट्र पोलीस भरती १००-प्रश्न साप्ताहिक चाचणी';

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.mediumImpact();
          await Future.wait([
            ref.read(userStoreProvider.notifier).refreshProfile(),
            SyncService().pullProgress(),
            _loadActiveTest(),
          ]);
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
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 40),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLiveNow ? '🔴 LIVE NOW' : '🏆 100-MARK CHAMPIONSHIP',
                                style: AppTextStyles.label.copyWith(
                                  color: isDark ? AppColors.canaryYellow : const Color(0xFF996B00),
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fade().slideY(begin: -0.2),

                        // Reminder Bell
                        GestureDetector(
                          onTap: () {
                            setState(() => _isReminderSet = !_isReminderSet);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(_isReminderSet ? 'Reminder Set for Weekly Test!' : 'Reminder Cancelled'),
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
                    const SizedBox(height: 24),

                    // Test Title
                    Text(
                      testTitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.h2.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fade(delay: 50.ms),

                    const SizedBox(height: 16),

                    // Calendar Scheduled Date Badge
                    if (_activeTest != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white12 : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_month, size: 15, color: AppColors.primaryMint),
                            const SizedBox(width: 6),
                            Text(
                              _formatDateString(_activeTest!.scheduledDate),
                              style: AppTextStyles.label.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_activeTest!.startTime != null) ...[
                              Text(' • ', style: TextStyle(color: textSubtle)),
                              const Icon(Icons.access_time, size: 14, color: AppColors.primaryMint),
                              const SizedBox(width: 4),
                              Text(
                                _activeTest!.startTime!.split('T').last.substring(0, 5),
                                style: AppTextStyles.label.copyWith(color: textColor),
                              ),
                            ],
                          ],
                        ),
                      ).animate().fade(delay: 80.ms),

                    const SizedBox(height: 16),

                    Text(
                      isLiveNow ? 'Test is Currently Open!' : 'Official Mock Test Starts In:',
                      style: AppTextStyles.body.copyWith(color: textMuted),
                    ).animate().fade(delay: 100.ms),
                    const SizedBox(height: 10),

                    // Glowing Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                          fontSize: 34,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 1.seconds),
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
                    // Exam Category Selection
                    Row(
                      children: [
                        Text('Exam Category', style: AppTextStyles.h3.copyWith(color: textColor)),
                        if (_isLoadingTest) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryMint),
                          ),
                        ],
                      ],
                    ),
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
                            onTap: () {
                              setState(() => _selectedExamType = type);
                              _loadActiveTest();
                            },
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
                    const SizedBox(height: 28),

                    // Test Specifications
                    Text('100-Mark Blueprint', style: AppTextStyles.h3.copyWith(color: textColor)).animate().fade(delay: 400.ms),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: cardBorder),
                        boxShadow: isDark ? null : AppColors.softCardShadow,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SpecItem(
                                icon: Icons.quiz_outlined,
                                value: '$questionCount',
                                label: 'Questions',
                                isDark: isDark,
                              ),
                              Container(width: 1, height: 40, color: dividerColor),
                              _SpecItem(
                                icon: Icons.timer_outlined,
                                value: '${_activeTest?.durationMinutes ?? 90}',
                                label: 'Minutes',
                                isDark: isDark,
                              ),
                              Container(width: 1, height: 40, color: dividerColor),
                              _SpecItem(
                                icon: Icons.military_tech_outlined,
                                value: '${_activeTest?.totalMarks ?? 100}',
                                label: 'Total Marks',
                                isDark: isDark,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          const Divider(height: 1),
                          const SizedBox(height: 14),
                          // Syllabus breakdown
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _SubjectChip('मराठी: २५', isDark),
                              _SubjectChip('सामान्य ज्ञान: २५', isDark),
                              _SubjectChip('अंकगणित: २५', isDark),
                              _SubjectChip('बुद्धिमत्ता: २५', isDark),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 28),

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
                            'Championship Rewards',
                            style: AppTextStyles.h3.copyWith(
                              color: isDark ? AppColors.canaryYellow : const Color(0xFFB38600),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(children: [
                                const Text('💎 ', style: TextStyle(fontSize: 18)),
                                Text('+1000 XP', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                              ]),
                              Container(width: 1, height: 20, color: dividerColor),
                              Row(children: [
                                const Text('🥇 ', style: TextStyle(fontSize: 18)),
                                Text('State Rank', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                              ]),
                              Container(width: 1, height: 20, color: dividerColor),
                              Row(children: [
                                const Text('❤️ ', style: TextStyle(fontSize: 18)),
                                Text('Full Reset', style: AppTextStyles.body.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                              ]),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 600.ms).slideY(begin: 0.1),

                    const SizedBox(height: 40),

                    // Start Official Mock Test Button
                    GestureDetector(
                      onTap: _startTest,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryMint,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryMint.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'START OFFICIAL 100-MOCK TEST',
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.deepTealNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                    ).animate().fade(delay: 700.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),

                    const SizedBox(height: 40),
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
        const SizedBox(height: 10),
        Text(value, style: AppTextStyles.h2.copyWith(color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(color: isDark ? Colors.white54 : AppColors.textSecondary)),
      ],
    );
  }
}

class _SubjectChip extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SubjectChip(this.label, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFBBF7D0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white70 : const Color(0xFF166534),
        ),
      ),
    );
  }
}
