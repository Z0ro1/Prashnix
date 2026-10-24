import 'package:flutter/material.dart';
import 'package:chiclet/chiclet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../providers/skill_tree_provider.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';

class SkillTreeNodeBuilder extends StatefulWidget {
  final SkillNode node;
  final int index;
  final bool isLastNode;
  final Color unitColor;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onStart;

  const SkillTreeNodeBuilder({
    super.key,
    required this.node,
    required this.index,
    required this.isLastNode,
    required this.unitColor,
    required this.isSelected,
    required this.onTap,
    required this.onStart,
  });

  @override
  State<SkillTreeNodeBuilder> createState() => _SkillTreeNodeBuilderState();
}

class _SkillTreeNodeBuilderState extends State<SkillTreeNodeBuilder> {
  bool _showTooltip = false;

  double _getOffsetForIndex(int idx) {
    // Left zig-zag first
    final pattern = [0.0, -0.5, -0.85, -0.5, 0.0, 0.5, 0.85, 0.5];
    return pattern[idx % pattern.length];
  }

  Color _darkenColor(Color color, [double amount = .2]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final currentOffset = _getOffsetForIndex(widget.index);
    final bool isActive = widget.node.status == NodeStatus.active;
    final bool isLocked = widget.node.status == NodeStatus.locked;
    final bool isCompleted = widget.node.status == NodeStatus.completed;

    Color baseColor;
    if (isLocked) {
      baseColor = const Color(0xFFB0B0B0); // some grey color for locked
    } else if (widget.node.icon == 'chest') {
      baseColor = AppColors.canaryYellow;
    } else {
      baseColor = const Color(0xFFA5C653); // requested green color
    }

    final iconColor = isLocked ? Colors.grey.shade400 : Colors.white;

    final screenWidth = MediaQuery.of(context).size.width;
    final displacement = currentOffset * math.min(screenWidth * 0.35, 120.0);

    final double progress = widget.node.totalLessons > 0
        ? widget.node.completedLessons / widget.node.totalLessons
        : 0.0;

    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Transform.translate(
          offset: Offset(displacement, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tooltip Bubble
              if (isActive && _showTooltip)
                GestureDetector(
                  onTap: widget.onStart,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2A2A3A), Color(0xFF1A1A2A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: widget.unitColor.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt_rounded,
                              color: AppColors.foxOrange,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'START +25 XP',
                              style: AppTextStyles.labelLarge.copyWith(
                                color: Colors.white,
                                letterSpacing: 1.2,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: const Size(16, 10),
                        painter: _TrianglePainter(
                          color: const Color(0xFF1A1A2A),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              else
                const SizedBox(height: 8),

              // 3D Glass Node replaced by Chiclet
              Custom3DNode(
                isLocked: isLocked,
                isActive: isActive,
                isCompleted: isCompleted,
                baseColor: baseColor,
                progress: progress,
                onPressed: (isLocked || isCompleted)
                    ? () {}
                    : () {
                        if (isActive && !_showTooltip) {
                          setState(() => _showTooltip = true);
                        } else {
                          widget.onTap();
                        }
                      },
                child: Center(
                  child: Icon(
                    isCompleted
                        ? Icons.check_rounded
                        : _getIconData(widget.node.icon),
                    color: isCompleted
                        ? _darkenColor(baseColor, 0.4)
                        : iconColor,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.bolt_rounded;
      case 'dumbbell':
        return Icons.fitness_center_rounded;
      case 'chest':
        return Icons.redeem_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}

class Custom3DNode extends StatelessWidget {
  final bool isLocked;
  final bool isCompleted;
  final bool isActive;
  final Color baseColor;
  final VoidCallback? onPressed;
  final Widget child;
  final double progress;

  const Custom3DNode({
    super.key,
    required this.isLocked,
    required this.isCompleted,
    required this.isActive,
    required this.baseColor,
    required this.onPressed,
    required this.child,
    this.progress = 0.0,
  });

  Color _darken(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final glowColor = isActive
        ? baseColor.withValues(alpha: 0.5)
        : Colors.transparent;
    final backgroundColor = baseColor;
    final buttonColor = _darken(baseColor, 0.25);

    return Container(
      margin: const EdgeInsets.only(top: 10.0, bottom: 8.0),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Removed Ambient Outer Glow

          // Pulsing Ring for Active Node
          if (isActive)
            const PulsingRing(
              width: 105,
              height: 90,
              color: AppColors.foxOrange, // Vibrant contrast against the green node
            ),

          // Chiclet Button
          isLocked
              ? ChicletAnimatedButton(
                  onPressed: onPressed,
                  width: 90,
                  height: 75,
                  buttonHeight: 12,
                  backgroundColor: const Color(0xFFE0E0E0), // Light grey face
                  buttonColor: const Color(0xFF9E9E9E), // Dark grey shadow
                  buttonType: ChicletButtonTypes.oval,
                  child: SizedBox(
                    width: 90,
                    height: 75,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Organic Random Blob Texture
                        Positioned.fill(
                          child: ClipOval(
                            child: CustomPaint(
                              painter: NodeTexturePainter(
                                color: Colors.black.withValues(alpha: 0.06), // Very faint natural darkening
                              ),
                            ),
                          ),
                        ),
                        // Node Icon
                        child,
                      ],
                    ),
                  ),
                )
              : ChicletAnimatedButton(
                  onPressed: onPressed,
                  width: 90,
                  height: 75,
                  buttonHeight: 12,
                  backgroundColor: backgroundColor,
                  buttonColor: buttonColor,
                  buttonType: ChicletButtonTypes.oval,
                  child: SizedBox(
                    width: 90,
                    height: 75,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Organic Random Blob Texture
                        Positioned.fill(
                          child: ClipOval(
                            child: CustomPaint(
                              painter: NodeTexturePainter(
                                color: Colors.black.withValues(alpha: 0.06), // Very faint natural darkening
                              ),
                            ),
                          ),
                        ),
                        // Node Icon
                        child,
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// CustomPainter that draws natural, randomized organic blobs
class NodeTexturePainter extends CustomPainter {
  final Color color;

  NodeTexturePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Large sweeping blob from bottom-left extending inwards
    final path1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.3, size.width * 0.45, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.9, size.width * 0.1, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Soft blob hanging from the top right
    final path2 = Path()
      ..moveTo(size.width * 0.4, 0)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.25, size.width, size.height * 0.35)
      ..lineTo(size.width, 0)
      ..close();

    // Small speck/blob on the bottom right edge
    final path3 = Path()
      ..moveTo(size.width * 0.75, size.height)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.75, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path1, paint);
    canvas.drawPath(path2, paint);
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PulsingRing extends StatefulWidget {
  final double width;
  final double height;
  final Color color;

  const PulsingRing({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
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
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.height / 2),
                border: Border.all(
                  color: widget.color,
                  width: 4, // thick ring
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
