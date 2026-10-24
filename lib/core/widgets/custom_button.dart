import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/providers/settings_provider.dart';
import '../constants/app_constants.dart';

enum ButtonVariant { primaryMint, primaryGreen, secondaryNavy, outline, disabled, success, error }

class CustomButton extends ConsumerStatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final double elevation;
  final Color? backgroundColor;
  final Color? shadowColor;
  final Color? textColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primaryMint,
    this.icon,
    this.isLoading = false,
    this.elevation = 4.0,
    this.backgroundColor,
    this.shadowColor,
    this.textColor,
  });

  @override
  ConsumerState<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends ConsumerState<CustomButton> {
  bool _isPressed = false;

  void _onPointerDown(PointerDownEvent event) {
    if (widget.variant == ButtonVariant.disabled || widget.isLoading) return;
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    setState(() => _isPressed = true);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (widget.variant == ButtonVariant.disabled || widget.isLoading) return;
    setState(() => _isPressed = false);
    widget.onPressed?.call();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (widget.variant == ButtonVariant.disabled || widget.isLoading) return;
    setState(() => _isPressed = false);
  }

  Color _getBaseColor(BuildContext context) {
    if (widget.backgroundColor != null) return widget.backgroundColor!;
    switch (widget.variant) {
      case ButtonVariant.primaryMint:
        return AppColors.featherGreen;
      case ButtonVariant.primaryGreen:
        return AppColors.primaryGreen;
      case ButtonVariant.success:
        return AppColors.success;
      case ButtonVariant.error:
        return AppColors.error;
      case ButtonVariant.secondaryNavy:
        return AppColors.skyBlue;
      case ButtonVariant.outline:
        return Theme.of(context).scaffoldBackgroundColor;
      case ButtonVariant.disabled:
        return Theme.of(context).brightness == Brightness.dark 
            ? AppColors.surfaceDark 
            : AppColors.borderLight;
    }
  }

  Color _getTextColor(BuildContext context) {
    if (widget.textColor != null) return widget.textColor!;
    switch (widget.variant) {
      case ButtonVariant.primaryMint:
      case ButtonVariant.primaryGreen:
      case ButtonVariant.success:
      case ButtonVariant.error:
      case ButtonVariant.secondaryNavy:
        return Colors.white;
      case ButtonVariant.outline:
        return Theme.of(context).brightness == Brightness.dark 
            ? AppColors.textPrimaryDark 
            : AppColors.textPrimaryLight;
      case ButtonVariant.disabled:
        return Theme.of(context).brightness == Brightness.dark 
            ? AppColors.textMutedDark 
            : AppColors.textMutedLight;
    }
  }

  Border? _getBorder(BuildContext context) {
    if (widget.variant == ButtonVariant.outline) {
      return Border.all(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.borderDark 
            : AppColors.borderLight, 
        width: 2,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isActuallyDisabled = widget.variant == ButtonVariant.disabled || widget.isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = _getBaseColor(context);
    final textColor = _getTextColor(context);

    final content = Center(
      child: widget.isLoading
          ? SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: textColor, size: 20),
                  const SizedBox(width: AppConstants.paddingSmall),
                ],
                Text(
                  widget.text, // Removed uppercase for a cleaner look
                  style: AppTypography.labelLarge.copyWith(
                    color: textColor,
                  ),
                ),
              ],
            ),
    );

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: 56,
        transform: Matrix4.diagonal3Values(
          _isPressed ? 0.97 : 1.0, 
          _isPressed ? 0.97 : 1.0, 
          1.0
        ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActuallyDisabled ? (isDark ? AppColors.surfaceDimDark : AppColors.surfaceDimLight) : baseColor,
          borderRadius: BorderRadius.circular(16),
          border: _getBorder(context),
          boxShadow: isActuallyDisabled || _isPressed || widget.variant == ButtonVariant.outline
              ? null
              : AppColors.softCardShadow,
        ),
        child: content,
      ),
    );
  }
}
