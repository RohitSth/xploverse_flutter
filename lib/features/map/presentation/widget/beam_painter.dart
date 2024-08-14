import 'package:flutter/material.dart';
import 'dart:math' as math;

class BeamPainter extends CustomPainter {
  final double direction;
  final double beamWidth;

  BeamPainter({required this.direction, this.beamWidth = 60.0});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final Path path = Path();
    final double adjustedDirection =
        direction - 90.0; // Adjusting by 90 degrees
    final double startAngle = adjustedDirection - (beamWidth / 2);
    final double sweepAngle = beamWidth;

    final Rect rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width * 2);
    path.moveTo(size.width / 2, size.height / 2);
    path.arcTo(rect, startAngle * (math.pi / 180), sweepAngle * (math.pi / 180),
        false);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
