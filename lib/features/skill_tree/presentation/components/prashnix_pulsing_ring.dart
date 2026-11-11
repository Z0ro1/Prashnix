import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/prashnix_colors.dart';

class PrashnixPulsingRing extends StatefulWidget {
  final double size;
  final Widget child;
  final Color? pulseColor;
  final int totalLessons;
  final int completedLessons;
  final double? progress; // Backwards compatibility if passed directly
  final Color? progressColor;
  final Color? trackColor;
  final double strokeWidth;

  const PrashnixPulsingRing({
    super.key,
    required this.size,
    required this.child,
    this.pulseColor,
    this.totalLessons = 5,
    this.completedLessons = 0,
    this.progress,
    this.progressColor,
    this.trackColor,
    this.strokeWidth = 7.0,
  });

  @override
  State<PrashnixPulsingRing> createState() => _PrashnixPulsingRingState();
}

class _PrashnixPulsingRingState extends State<PrashnixPulsingRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coreColor = widget.pulseColor ?? PrashnixColors.green;

    final arcProgressColor = widget.progressColor ?? PrashnixColors.yellow;
    final arcTrackColor = widget.trackColor ??
        (isDark ? Colors.white.withValues(alpha: 0.22) : const Color(0xFFE2E4E9));

    final safeTotalLessons = math.max(1, widget.totalLessons);
    final targetCompleted = widget.progress != null && widget.completedLessons == 0
        ? (widget.progress! * safeTotalLessons).clamp(0.0, safeTotalLessons.toDouble())
        : widget.completedLessons.clamp(0, safeTotalLessons).toDouble();

    return SizedBox(
      width: widget.size * 1.35,
      height: widget.size * 1.35,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer Pulsing Glow Wave (Pulses cleanly outside the progress ring)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size + 8,
                  height: widget.size + 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: coreColor.withValues(alpha: _opacityAnimation.value),
                      width: 4,
                    ),
                  ),
                ),
              );
            },
          ),
          // Segmented Circular Progress Ring (Duolingo-style with gaps between lessons)
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: targetCompleted),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, animatedCompleted, _) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _SegmentedProgressRingPainter(
                  totalLessons: safeTotalLessons,
                  completedLessons: animatedCompleted,
                  trackColor: arcTrackColor,
                  progressColor: arcProgressColor,
                  strokeWidth: widget.strokeWidth,
                ),
              );
            },
          ),
          // The Center Node Button
          widget.child,
        ],
      ),
    );
  }
}

class _SegmentedProgressRingPainter extends CustomPainter {
  final int totalLessons;
  final double completedLessons;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  const _SegmentedProgressRingPainter({
    required this.totalLessons,
    required this.completedLessons,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 7.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (totalLessons <= 1) {
      // Single continuous track ring
      canvas.drawCircle(center, radius, trackPaint);

      if (completedLessons > 0.0) {
        final sweep = 2 * math.pi * completedLessons.clamp(0.0, 1.0);
        canvas.drawArc(
          rect,
          -math.pi / 2,
          sweep,
          false,
          progressPaint,
        );
      }
      return;
    }

    // Segmented ring with Duolingo-style gaps between lessons
    final slotAngle = (2 * math.pi) / totalLessons;

    // For StrokeCap.round, each cap extends outward by strokeWidth / 2 along the tangent.
    // Between two adjacent rounded caps, the tips get closer by strokeWidth (strokeWidth / 2 * 2).
    // To ensure an actual visible space of ~9px between the rounded cap tips:
    const desiredVisibleGap = 9.0;
    final desiredGapAngle = (desiredVisibleGap + strokeWidth) / radius;

    // Clamp gapAngle so that segments don't vanish if totalLessons is unusually large (e.g. 10+)
    final gapAngle = desiredGapAngle.clamp(0.12, slotAngle * 0.40);
    final segmentSweep = slotAngle - gapAngle;

    // Start with a gap centered at the top (12 o'clock, -pi / 2).
    // Lesson 1 starts immediately clockwise after the top gap.
    final baseStartAngle = -math.pi / 2 + (gapAngle / 2);

    for (int i = 0; i < totalLessons; i++) {
      final startAngle = baseStartAngle + (i * slotAngle);

      // 1. Draw background track segment
      canvas.drawArc(
        rect,
        startAngle,
        segmentSweep,
        false,
        trackPaint,
      );

      // 2. Draw completed / animated progress segment
      if (completedLessons > i) {
        final fillRatio = (completedLessons - i).clamp(0.0, 1.0);
        if (fillRatio > 0.001) {
          final progressSweep = segmentSweep * fillRatio;
          canvas.drawArc(
            rect,
            startAngle,
            progressSweep,
            false,
            progressPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentedProgressRingPainter oldDelegate) {
    return oldDelegate.totalLessons != totalLessons ||
        oldDelegate.completedLessons != completedLessons ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
