import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class DuolingoButton extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color shadowColor;
  final VoidCallback? onPressed;
  final double width;
  final double height;
  final double elevation;
  final bool isLocked;
  final bool isActive;
  final BoxShape shape;
  final BorderRadiusGeometry? borderRadius;

  const DuolingoButton({
    super.key,
    required this.child,
    required this.baseColor,
    required this.shadowColor,
    this.onPressed,
    this.width = 80,
    this.height = 80,
    this.elevation = 8.0,
    this.isLocked = false,
    this.isActive = false,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  @override
  State<DuolingoButton> createState() => _DuolingoButtonState();
}

class _DuolingoButtonState extends State<DuolingoButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(DuolingoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isActive && oldWidget.isActive) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (widget.onPressed == null || widget.isLocked) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.onPressed == null || widget.isLocked) return;
    setState(() => _isPressed = false);
    widget.onPressed!();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (widget.onPressed == null || widget.isLocked) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final double currentElevation = _isPressed ? 0 : widget.elevation;
    
    // Calculate color based on state
    Color actualBaseColor = widget.baseColor;
    Color actualShadowColor = widget.shadowColor;
    
    if (widget.isLocked) {
      actualBaseColor = AppColors.surfaceLight;
      actualShadowColor = AppColors.surfaceLight;
    }

    Widget buttonContent = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: actualBaseColor,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: widget.isLocked ? 0.3 : 0.6),
          width: 3,
        ),
        boxShadow: [
          // The solid 3D shadow
          BoxShadow(
            color: actualShadowColor,
            offset: Offset(0, currentElevation),
            blurRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: widget.isLocked 
            ? const Icon(Icons.lock_rounded, color: Colors.grey, size: 32)
            : widget.child,
      ),
    );

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = widget.isActive ? 1.0 + (_pulseController.value * 0.05) : 1.0;
        final glowOpacity = widget.isActive ? (_pulseController.value * 0.5) : 0.0;
        
        return Transform.scale(
          scale: scale,
          child: Listener(
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring for active nodes
                if (widget.isActive)
                  Container(
                    width: widget.width + 16,
                    height: widget.height + 16,
                    decoration: BoxDecoration(
                      shape: widget.shape,
                      borderRadius: widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
                      border: Border.all(
                        color: widget.baseColor.withOpacity(0.5 * glowOpacity),
                        width: 4,
                      ),
                    ),
                  ),
                  
                // The button itself
                AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(top: widget.elevation - currentElevation),
                  child: buttonContent,
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
