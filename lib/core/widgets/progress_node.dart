import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum NodeState { active, completed, locked }

class ProgressNode extends StatefulWidget {
  final NodeState state;
  final VoidCallback? onTap;
  final double size;

  const ProgressNode({
    super.key,
    required this.state,
    this.onTap,
    this.size = 60.0,
  });

  @override
  State<ProgressNode> createState() => _ProgressNodeState();
}

class _ProgressNodeState extends State<ProgressNode> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    if (widget.state == NodeState.active) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProgressNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state == NodeState.active && oldWidget.state != NodeState.active) {
      _glowController.repeat(reverse: true);
    } else if (widget.state != NodeState.active && oldWidget.state == NodeState.active) {
      _glowController.stop();
      _glowController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.state != NodeState.locked ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final isLocked = widget.state == NodeState.locked;
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLocked ? AppColors.surfaceDimLight : AppColors.surfaceLight,
              border: Border.all(
                color: _getBorderColor(),
                width: 3,
              ),
              boxShadow: [
                // 3D Bottom Shadow
                BoxShadow(
                  color: _getShadowColor(),
                  blurRadius: 0,
                  offset: const Offset(0, 6),
                ),
                // Soft ambient shadow
                const BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
                // Optional glow for active state
                if (widget.state == NodeState.active)
                  BoxShadow(
                    color: AppColors.primaryMint.withValues(alpha: 0.4),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 3,
                  )
              ],
            ),
            child: Center(
              child: _getIcon(),
            ),
          );
        },
      ),
    );
  }

  Color _getBorderColor() {
    switch (widget.state) {
      case NodeState.active:
      case NodeState.completed:
        return AppColors.primaryMint;
      case NodeState.locked:
        return AppColors.borderLight;
    }
  }

  Color _getShadowColor() {
    switch (widget.state) {
      case NodeState.active:
      case NodeState.completed:
        return AppColors.primaryGreenDark;
      case NodeState.locked:
        return AppColors.borderLight;
    }
  }

  Widget _getIcon() {
    switch (widget.state) {
      case NodeState.active:
        return const Icon(Icons.star_rounded, color: AppColors.accentAmber, size: 28);
      case NodeState.completed:
        return const Icon(Icons.check_rounded, color: AppColors.primaryMint, size: 28);
      case NodeState.locked:
        return const Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 24);
    }
  }
}
