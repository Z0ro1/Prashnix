import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/heart_economy_provider.dart';

class HeartRegenTimerWidget extends ConsumerStatefulWidget {
  const HeartRegenTimerWidget({super.key});

  @override
  ConsumerState<HeartRegenTimerWidget> createState() => _HeartRegenTimerWidgetState();
}

class _HeartRegenTimerWidgetState extends ConsumerState<HeartRegenTimerWidget> {
  Timer? _timer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        // Trigger re-evaluation when timer hits 0
        ref.read(heartEconomyProvider.notifier).evaluateRegeneration(DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes from provider
    ref.listen<int>(heartEconomyProvider, (previous, next) {
      setState(() {
        _secondsRemaining = next;
      });
    });

    if (_secondsRemaining <= 0) return const SizedBox.shrink();

    final minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite,
            color: AppColors.error,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '+1 in $minutes:$seconds',
            style: AppTextStyles.label.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
