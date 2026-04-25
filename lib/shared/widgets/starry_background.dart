import 'package:flutter/material.dart';

import 'magical/starfield_background.dart';

/// Decorative star layer with subtle animation.
class StarryBackground extends StatelessWidget {
  const StarryBackground({
    super.key,
    required this.child,
    this.starCount = 34,
  });

  final Widget child;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    return StarfieldBackground(starCount: starCount, child: child);
  }
}
