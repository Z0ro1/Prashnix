import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../quiz/presentation/screens/quiz_screen.dart';

class WeeklyTestBannerWidget extends StatefulWidget {
  const WeeklyTestBannerWidget({super.key});

  @override
  State<WeeklyTestBannerWidget> createState() => _WeeklyTestBannerWidgetState();
}

class _WeeklyTestBannerWidgetState extends State<WeeklyTestBannerWidget> {
  late Timer _timer;
  Duration _timeUntilSunday = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilSunday();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      _calculateTimeUntilSunday();
    });
  }

  void _calculateTimeUntilSunday() {
    final now = DateTime.now();
    // Sunday is 7 in Dart's DateTime.
    // If today is Sunday, the next Sunday is in 7 days (or 0 days if we consider it currently active, but let's count to next midnight)
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) {
      daysUntilSunday += 7;
    }

    final nextSunday = DateTime(now.year, now.month, now.day + daysUntilSunday);
    setState(() {
      _timeUntilSunday = nextSunday.difference(now);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeUntilSunday.inDays;
    final hours = _timeUntilSunday.inHours.remainder(24);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF6B4EFF), // Vibrant Purple
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100-Mark Weekly Test',
                  style: AppTextStyles.h3.copyWith(color: Colors.white),
                ),
                Text(
                  'Resets in $days days, $hours hrs',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QuizScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ENTER',
                style: AppTextStyles.label.copyWith(
                  color: const Color(0xFF6B4EFF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
