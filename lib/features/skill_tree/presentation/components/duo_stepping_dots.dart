import 'package:flutter/material.dart';
import '../theme/duo_colors.dart';

class DuoSteppingDots extends StatelessWidget {
  final int count;
  final Offset startOffset;
  final Offset endOffset;

  const DuoSteppingDots({
    super.key,
    required this.count,
    required this.startOffset,
    required this.endOffset,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      painter: _SteppingDotsPainter(
        count: count,
        start: startOffset,
        end: endOffset,
        color: isDark ? const Color(0xFF283B46) : DuoColors.steppingDot,
      ),
    );
  }
}

class _SteppingDotsPainter extends CustomPainter {
  final int count;
  final Offset start;
  final Offset end;
  final Color color;

  _SteppingDotsPainter({
    required this.count,
    required this.start,
    required this.end,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const double radius = 4.0; // 8px diameter

    for (int i = 1; i <= count; i++) {
      final double t = i / (count + 1);
      final double x = start.dx + (end.dx - start.dx) * t;
      final double y = start.dy + (end.dy - start.dy) * t;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteppingDotsPainter oldDelegate) =>
      oldDelegate.start != start ||
      oldDelegate.end != end ||
      oldDelegate.count != count ||
      oldDelegate.color != color;
}
