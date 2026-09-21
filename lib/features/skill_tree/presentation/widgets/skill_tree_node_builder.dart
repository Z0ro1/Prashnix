import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../providers/skill_tree_provider.dart';
import 'duolingo_button.dart';

class SkillTreeNodeBuilder extends StatelessWidget {
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

  double _getOffsetForIndex(int idx) {
    // 0 = Center, -1 = Left, 1 = Right
    final pattern = [0.0, 0.6, 0.8, 0.6, 0.0, -0.6, -0.8, -0.6];
    return pattern[idx % pattern.length];
  }

  // To create slightly darker shadow colors dynamically
  Color _darkenColor(Color color, [double amount = .2]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final currentOffset = _getOffsetForIndex(index);
    final bool isActive = node.status == NodeStatus.active;
    final bool isLocked = node.status == NodeStatus.locked;
    final bool isCompleted = node.status == NodeStatus.completed;

    Color baseColor;
    Color shadowColor;

    if (isLocked) {
      baseColor = AppColors.border; // Grey
      shadowColor = _darkenColor(baseColor, 0.1);
    } else if (node.icon == 'chest') {
      baseColor = AppColors.canaryYellow;
      shadowColor = _darkenColor(baseColor, 0.15);
    } else {
      // Use the unit color for completed or active standard nodes
      baseColor = unitColor;
      shadowColor = _darkenColor(unitColor, 0.15);
    }

    return SizedBox(
      height: 120, 
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Interactive Node
          Align(
            alignment: Alignment(currentOffset, 0),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isLocked && !isCompleted && node.totalLessons > 0)
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: node.completedLessons / node.totalLessons,
                        strokeWidth: 6,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: AlwaysStoppedAnimation<Color>(unitColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  DuolingoButton(
                    isLocked: isLocked,
                    isActive: isActive,
                    baseColor: baseColor,
                    shadowColor: shadowColor,
                    onPressed: (isLocked || isCompleted) ? null : onTap,
                    child: _RotatingIcon(
                      iconData: _getIconData(node.icon),
                      color: isLocked ? Colors.grey.shade400 : Colors.white,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tooltip Bubble removed
        ],
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_rounded;
      case 'dumbbell':
        return Icons.fitness_center_rounded;
      case 'chest':
        return Icons.redeem_rounded;
      default:
        return Icons.star_rounded;
    }
  }
}



class _RotatingIcon extends StatefulWidget {
  final IconData iconData;
  final Color color;
  final double size;

  const _RotatingIcon({
    required this.iconData,
    required this.color,
    required this.size,
  });

  @override
  State<_RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<_RotatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _translateY;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    // 5 seconds total cycle
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    // Bounce up (0.0 - 0.1), stay up until 0.3, bounce down (0.3 - 0.4), idle (0.4 - 1.0)
    _translateY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(-8.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 60),
    ]).animate(_controller);

    // Rotate while up (0.1 - 0.3)
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70), // stays at 1.0 (full circle)
    ]).animate(_controller);

    _controller.repeat();
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
        return Transform.translate(
          offset: Offset(0, _translateY.value),
          child: Transform.rotate(
            angle: _rotation.value * 2 * 3.141592653589793,
            child: Icon(
              widget.iconData,
              color: widget.color,
              size: widget.size,
            ),
          ),
        );
      },
    );
  }
}

