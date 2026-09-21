import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class WindingPathPainter extends CustomPainter {
  final double startXOffset; // -1 (left), 0 (center), 1 (right)
  final double endXOffset;   // -1 (left), 0 (center), 1 (right)
  final bool isCompleted;    // Whether this path segment is "unlocked"

  WindingPathPainter({
    required this.startXOffset,
    required this.endXOffset,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // We are drawing from the center of THIS node down to the center of the NEXT node
    // Let's assume the node itself occupies the center vertically of this size constraint
    final double centerX = size.width / 2;
    final double amplitude = size.width * 0.25; // How far it swings left/right
    
    final double startX = centerX + (startXOffset * amplitude);
    final double startY = size.height / 2; // Middle of this row

    final double endX = centerX + (endXOffset * amplitude);
    final double endY = size.height + (size.height / 2); // Middle of next row

    final paint = Paint()
      ..color = isCompleted ? AppColors.featherGreen : AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(startX, startY);

    // Draw a smooth bezier curve
    final double controlPointY1 = startY + (endY - startY) * 0.5;
    final double controlPointX1 = startX;
    
    final double controlPointY2 = startY + (endY - startY) * 0.5;
    final double controlPointX2 = endX;

    path.cubicTo(
      controlPointX1, controlPointY1,
      controlPointX2, controlPointY2,
      endX, endY,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WindingPathPainter oldDelegate) {
    return oldDelegate.startXOffset != startXOffset ||
           oldDelegate.endXOffset != endXOffset ||
           oldDelegate.isCompleted != isCompleted;
  }
}
