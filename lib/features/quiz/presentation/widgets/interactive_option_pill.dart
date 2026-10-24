import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../profile/presentation/providers/settings_provider.dart';

enum OptionState { defaultState, selected, correct, incorrect }

class InteractiveOptionPill extends ConsumerStatefulWidget {
  final String label;
  final String text;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color coreColor;
    Color bgColor;
    Color borderColor;
    Color textColor;
    bool isActive = widget.state != OptionState.defaultState;

    switch (widget.state) {
      case OptionState.selected:
        coreColor = AppColors.primaryGreen;
        bgColor = isDark ? AppColors.primaryGreen.withValues(alpha: 0.15) : AppColors.primaryGreen.withValues(alpha: 0.1);
        borderColor = AppColors.primaryGreen;
        textColor = isDark ? Colors.white : AppColors.primaryGreenDark;
        break;
      case OptionState.correct:
        coreColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.15);
        borderColor = AppColors.success;
        textColor = isDark ? Colors.white : AppColors.success;
        break;
      case OptionState.incorrect:
        coreColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.15);
        borderColor = AppColors.error;
        textColor = isDark ? Colors.white : AppColors.error;
        break;
      case OptionState.defaultState:
      default:
        coreColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
        bgColor = isDark ? AppColors.surfaceDimDark : AppColors.surfaceLight;
        borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
        textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        break;
    }

    final currentElevation = _isPressed ? 0.0 : _elevation;

    Widget pill = Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(
          bottom: 16 - _elevation + currentElevation,
          top: _elevation - currentElevation,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            // Soft shadow for 3D press effect
            if (!isActive || widget.state == OptionState.selected)
              BoxShadow(
                color: borderColor.withValues(alpha: isDark ? 0.3 : 0.2),
                offset: Offset(0, currentElevation),
                blurRadius: 0,
              ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive ? coreColor.withValues(alpha: 0.2) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? coreColor : borderColor,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.label,
                    style: AppTypography.labelLarge.copyWith(
                      color: isActive ? coreColor : coreColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.text,
                  style: AppTypography.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              if (widget.state == OptionState.correct)
                const Icon(Icons.check_circle, color: AppColors.success, size: 28),
              if (widget.state == OptionState.incorrect)
                const Icon(Icons.cancel, color: AppColors.error, size: 28),
            ],
          ),
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
          .shakeX(duration: 400.ms, amount: 6, hz: 8);
    }

    return pill;
  }
}
