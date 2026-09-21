import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/presentation/providers/settings_provider.dart';
import '../constants/app_constants.dart';

enum ButtonVariant { primaryMint, secondaryNavy, outline, disabled }

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

  Color _getShadowColor(BuildContext context) {
    if (widget.shadowColor != null) return widget.shadowColor!;
    switch (widget.variant) {
      case ButtonVariant.primaryMint:
        return AppColors.featherGreenShadow;
      case ButtonVariant.secondaryNavy:
        return AppColors.skyBlueShadow;
      case ButtonVariant.outline:
        return Theme.of(context).brightness == Brightness.dark 
            ? AppColors.borderDark 
            : AppColors.borderLight;
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
    final double currentElevation = _isPressed || isActuallyDisabled ? 0 : widget.elevation;
    
    final baseColor = _getBaseColor(context);
    final shadowColor = _getShadowColor(context);
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
                  widget.text.toUpperCase(),
                  style: AppTypography.button.copyWith(
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow / 3D Base Layer
          Container(
            height: 56 + widget.elevation,
            margin: EdgeInsets.only(top: widget.elevation),
            decoration: BoxDecoration(
              color: shadowColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          
          // Top interactive layer
          AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            curve: Curves.easeOut,
            height: 56,
            margin: EdgeInsets.only(top: currentElevation, bottom: widget.elevation - currentElevation),
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(16),
              border: _getBorder(context),
            ),
            child: content,
          ),
        ],
      ),
    );
  }
}
