import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrashnixButton extends StatefulWidget {
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

  const PrashnixButton({
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
  State<PrashnixButton> createState() => _PrashnixButtonState();
}

class _PrashnixButtonState extends State<PrashnixButton> with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(PrashnixButton oldWidget) {
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

    Widget buttonContent = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: actualBaseColor,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
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
        final glowOpacity = widget.isActive ? 0.3 + (_pulseController.value * 0.7) : 0.0;
        
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
                    margin: EdgeInsets.only(top: widget.elevation - currentElevation),
                    width: widget.width + 30,
                    height: widget.height + 30,
                    decoration: BoxDecoration(
                      shape: widget.shape,
                      borderRadius: widget.shape == BoxShape.rectangle ? widget.borderRadius : null,
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: glowOpacity),
                        width: 10,
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
