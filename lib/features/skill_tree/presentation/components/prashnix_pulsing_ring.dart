import 'package:flutter/material.dart';
import '../theme/prashnix_colors.dart';

class PrashnixPulsingRing extends StatefulWidget {
  final double size;
  final Widget child;
  final Color? pulseColor;

  const PrashnixPulsingRing({
    super.key,
    required this.size,
    required this.child,
    this.pulseColor,
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
    final coreColor = widget.pulseColor ?? PrashnixColors.green;
    final lightGlowColor = widget.pulseColor != null
        ? HSLColor.fromColor(coreColor).withLightness((HSLColor.fromColor(coreColor).lightness + 0.2).clamp(0.0, 1.0)).toColor()
        : PrashnixColors.greenLight;

    return SizedBox(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer Pulsing Glow Wave
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: coreColor.withValues(alpha: _opacityAnimation.value),
                      width: 6,
                    ),
                    color: lightGlowColor.withValues(
                      alpha: _opacityAnimation.value * 0.5,
                    ),
                  ),
                ),
              );
            },
          ),
          // Inner Static Base Glow
          Container(
            width: widget.size * 1.08,
            height: widget.size * 1.08,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lightGlowColor.withValues(alpha: 0.55),
            ),
          ),
          // The Center Node
          widget.child,
        ],
      ),
    );
  }
}
