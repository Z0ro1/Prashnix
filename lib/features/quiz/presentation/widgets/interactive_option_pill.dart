import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../profile/presentation/providers/settings_provider.dart';

enum OptionState { defaultState, selected, correct, incorrect }

class InteractiveOptionPill extends ConsumerStatefulWidget {
  final String label; // "A", "B", etc.
  final String text;  // The answer text
  final OptionState state;
  final VoidCallback onTap;

  const InteractiveOptionPill({
    super.key,
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  @override
  ConsumerState<InteractiveOptionPill> createState() => _InteractiveOptionPillState();
}

class _InteractiveOptionPillState extends ConsumerState<InteractiveOptionPill> {
  bool _isPressed = false;
  final double _elevation = 4.0;

  void _handlePointerDown(PointerDownEvent event) {
    if (widget.state == OptionState.defaultState || widget.state == OptionState.selected) {
      setState(() => _isPressed = true);
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
      if (ref.read(settingsProvider).hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      widget.onTap();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    Color borderColor;
    Color shadowColor;
    Color textColor;

    switch (widget.state) {
      case OptionState.selected:
        baseColor = AppColors.primaryMint.withValues(alpha: 0.1);
        borderColor = AppColors.primaryMint;
        shadowColor = AppColors.primaryMint.withValues(alpha: 0.3);
        textColor = AppColors.primaryMint;
        break;
      case OptionState.correct:
        baseColor = AppColors.featherGreen.withValues(alpha: 0.15);
        borderColor = AppColors.featherGreen;
        shadowColor = AppColors.featherGreen.withValues(alpha: 0.4);
        textColor = AppColors.featherGreen;
        break;
      case OptionState.incorrect:
        baseColor = AppColors.foxOrange.withValues(alpha: 0.15);
        borderColor = AppColors.foxOrange;
        shadowColor = AppColors.foxOrange.withValues(alpha: 0.4);
        textColor = AppColors.foxOrange;
        break;
      case OptionState.defaultState:
      default:
        baseColor = Colors.white;
        borderColor = AppColors.surfaceLighter;
        shadowColor = AppColors.surfaceLighter.withValues(alpha: 0.5);
        textColor = AppColors.textPrimary;
        break;
    }

    final currentElevation = _isPressed ? 0.0 : _elevation;

    Widget pill = Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        margin: EdgeInsets.only(
          bottom: 16 - _elevation + currentElevation,
          top: _elevation - currentElevation,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, currentElevation),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: widget.state == OptionState.defaultState 
                    ? AppColors.surfaceLight 
                    : borderColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.label,
                  style: AppTextStyles.label.copyWith(
                    color: widget.state == OptionState.defaultState ? AppColors.textSecondary : textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                widget.text,
                style: AppTextStyles.body.copyWith(
                  color: textColor,
                  fontWeight: widget.state != OptionState.defaultState ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (widget.state == OptionState.correct)
              const Icon(Icons.check_circle, color: AppColors.featherGreen),
            if (widget.state == OptionState.incorrect)
              const Icon(Icons.cancel, color: AppColors.foxOrange),
          ],
        ),
      ),
    );

    if (widget.state == OptionState.correct) {
      return pill.animate()
          .scale(duration: 300.ms, curve: Curves.easeOutBack, begin: const Offset(1, 1), end: const Offset(1.05, 1.05))
          .then()
          .scale(duration: 200.ms, curve: Curves.easeIn, end: const Offset(1, 1));
    } else if (widget.state == OptionState.incorrect) {
      return pill.animate()
          .shakeX(duration: 400.ms, amount: 4, hz: 6);
    }

    return pill;
  }
}
