import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/prashnix_colors.dart';
import 'prashnix_audio_service.dart';

enum PrashnixNodeType {
  completedCheck,
  completedChest,
  activeStar,
  locked,
}

class PrashnixPathNode extends StatefulWidget {
  final PrashnixNodeType type;
  final double size;
  final Color? activeColor;
  final VoidCallback? onTap;

  const PrashnixPathNode({
    super.key,
    required this.type,
    this.size = 78,
    this.activeColor,
    this.onTap,
  });

  @override
  State<PrashnixPathNode> createState() => _PrashnixPathNodeState();
}

class _PrashnixPathNodeState extends State<PrashnixPathNode> {
  bool _isPressed = false;

  Color _getTopColor(bool isDark) {
    switch (widget.type) {
      case PrashnixNodeType.completedCheck:
      case PrashnixNodeType.completedChest:
        return PrashnixColors.yellow;
      case PrashnixNodeType.activeStar:
        return widget.activeColor ?? PrashnixColors.green;
      case PrashnixNodeType.locked:
        return isDark ? const Color(0xFF283B46) : const Color(0xFFE5E5E5);
    }
  }

  Color _getShadowColor(bool isDark) {
    switch (widget.type) {
      case PrashnixNodeType.completedCheck:
      case PrashnixNodeType.completedChest:
        return PrashnixColors.yellowShadow;
      case PrashnixNodeType.activeStar:
        if (widget.activeColor != null) {
          final hsl = HSLColor.fromColor(widget.activeColor!);
          return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
        }
        return PrashnixColors.greenDarkBevel;
      case PrashnixNodeType.locked:
        return isDark ? const Color(0xFF1B2830) : const Color(0xFFCDCDCD);
    }
  }

  Widget _buildIcon(bool isDark) {
    switch (widget.type) {
      case PrashnixNodeType.completedCheck:
        return const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 42,
          weight: 900,
        );
      case PrashnixNodeType.completedChest:
        return const Text(
          '🎁',
          style: TextStyle(fontSize: 34),
        );
      case PrashnixNodeType.activeStar:
        return const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 48,
        );
      case PrashnixNodeType.locked:
        return Icon(
          Icons.lock_rounded,
          color: isDark ? const Color(0xFF8B9D9F) : const Color(0xFFAFAFAF),
          size: 36,
        );
    }
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (widget.type == PrashnixNodeType.activeStar) {
      PrashnixAudioService.playStarChime();
    } else if (widget.type == PrashnixNodeType.completedChest) {
      PrashnixAudioService.playGemsReward();
    } else if (widget.type == PrashnixNodeType.locked) {
      HapticFeedback.heavyImpact();
    } else {
      PrashnixAudioService.playTap();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const double bevelDepth = 6.0;
    final double currentTopOffset = _isPressed ? bevelDepth : 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _handleTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        width: widget.size,
        height: widget.size + bevelDepth,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // 3D Shadow Base
            Positioned(
              top: bevelDepth,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _getShadowColor(isDark),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Tactile Top Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              top: currentTopOffset,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _getTopColor(isDark),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _buildIcon(isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
