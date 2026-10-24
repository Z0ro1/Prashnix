import 'package:flutter/material.dart';
import '../theme/duo_colors.dart';
import '../theme/duo_text_styles.dart';

class DuoFloatingTooltip extends StatefulWidget {
  final String text;
  final Color? textColor;

  const DuoFloatingTooltip({
    super.key,
    this.text = 'START +25 XP',
    this.textColor,
  });

  @override
  State<DuoFloatingTooltip> createState() => _DuoFloatingTooltipState();
}

class _DuoFloatingTooltipState extends State<DuoFloatingTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: DuoColors.cardShadow,
                      offset: Offset(0, 4),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  widget.text,
                  style: widget.textColor != null
                      ? DuoTextStyles.pathTooltip.copyWith(color: widget.textColor)
                      : DuoTextStyles.pathTooltip,
                ),
              ),
              // Downward Triangle Pointer
              CustomPaint(
                size: const Size(14, 8),
                painter: _TooltipArrowPainter(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
