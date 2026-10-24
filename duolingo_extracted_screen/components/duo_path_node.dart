import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import 'duo_audio_service.dart';

enum DuoNodeType {
  completedCheck,
  completedChest,
  activeStar,
  locked,
}

class DuoPathNode extends StatefulWidget {
  final DuoNodeType type;
  final double size;
  final VoidCallback? onTap;

  const DuoPathNode({
    super.key,
    required this.type,
    this.size = 78,
    this.onTap,
  });

  @override
  State<DuoPathNode> createState() => _DuoPathNodeState();
}

class _DuoPathNodeState extends State<DuoPathNode> {
  bool _isPressed = false;

  Color get _topColor {
    switch (widget.type) {
      case DuoNodeType.completedCheck:
      case DuoNodeType.completedChest:
        return AppColors.yellow;
      case DuoNodeType.activeStar:
        return AppColors.green;
      case DuoNodeType.locked:
        return const Color(0xFFE5E5E5);
    }
  }

  Color get _shadowColor {
    switch (widget.type) {
      case DuoNodeType.completedCheck:
      case DuoNodeType.completedChest:
        return AppColors.yellowShadow;
      case DuoNodeType.activeStar:
        return AppColors.greenDarkBevel;
      case DuoNodeType.locked:
        return const Color(0xFFCDCDCD);
    }
  }

  Widget _buildIcon() {
    switch (widget.type) {
      case DuoNodeType.completedCheck:
        return const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 42,
          weight: 900,
        );
      case DuoNodeType.completedChest:
        return const Text(
          '🎁',
          style: TextStyle(fontSize: 34),
        );
      case DuoNodeType.activeStar:
        return const Icon(
          Icons.star_rounded,
          color: Colors.white,
          size: 48,
        );
      case DuoNodeType.locked:
        return const Icon(
          Icons.lock_rounded,
          color: Color(0xFFAFAFAF),
          size: 36,
        );
    }
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    if (widget.type == DuoNodeType.activeStar) {
      DuoAudioService.playStarChime();
    } else if (widget.type == DuoNodeType.completedChest) {
      DuoAudioService.playGemsReward();
    } else {
      DuoAudioService.playTap();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
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
          children: [
            // 3D Shadow Base
            Positioned(
              top: bevelDepth,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: _shadowColor,
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
                  color: _topColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: _buildIcon(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
