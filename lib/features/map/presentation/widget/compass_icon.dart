import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompassIcon extends StatelessWidget {
  final double direction;
  final bool isDarkMode;

  const CompassIcon({
    Key? key,
    required this.direction,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black54 : Colors.white70,
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(8),
      child: Transform.rotate(
        angle: direction * (math.pi / 180) * -1,
        child: const Icon(
          Icons.navigation_rounded, // This is the compass icon
          size: 30,
          color: Colors.red, // Set the color to red for the needle
        ),
      ),
    );
  }
}
