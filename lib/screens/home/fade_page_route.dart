import 'package:flutter/material.dart';

class FadePageRoute extends PageRouteBuilder {
  final Widget page;

  FadePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end);
            var opacityAnimation =
                animation.drive(tween.chain(CurveTween(curve: curve)));

            return FadeTransition(opacity: opacityAnimation, child: child);
          },
        );
}
