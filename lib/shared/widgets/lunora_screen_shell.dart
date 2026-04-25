import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'magical/starfield_background.dart';

/// Fond dégradé + option étoiles : base visuelle commune (accueil, parent, etc.).
class LunoraScreenShell extends StatelessWidget {
  const LunoraScreenShell({
    super.key,
    required this.child,
    this.useReaderGradient = false,
    this.showStarfield = false,
    this.starCount = 36,
  });

  final Widget child;
  final bool useReaderGradient;
  final bool showStarfield;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    final gradient = useReaderGradient
        ? LunoraColors.readerCanvasVertical
        : LunoraColors.nightSkyVertical;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        if (showStarfield)
          Positioned.fill(
            child: StarfieldBackground(
              starCount: starCount,
              child: child,
            ),
          )
        else
          Positioned.fill(child: child),
      ],
    );
  }
}
