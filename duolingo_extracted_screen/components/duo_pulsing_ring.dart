import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DuoPulsingRing extends StatefulWidget {
  final double size;
  final Widget child;

  const DuoPulsingRing({
    super.key,
    required this.size,
    required this.child,
  });

  @override
  State<DuoPulsingRing> createState() => _DuoPulsingRingState();
}

class _DuoPulsingRingState extends State<DuoPulsingRing>
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
    return SizedBox(
      width: widget.size * 1.4,
      height: widget.size * 1.4,
      child: Stack(
        alignment: Alignment.center,
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
                      color: AppColors.green.withValues(alpha: _opacityAnimation.value),
                      width: 6,
                    ),
                    color: AppColors.greenLight.withValues(
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
              color: AppColors.greenLight.withValues(alpha: 0.55),
            ),
          ),
          // The Center Node
          widget.child,
        ],
      ),
    );
  }
}
