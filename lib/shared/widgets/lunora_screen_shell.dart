import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import 'elunai_layout.dart';
import 'joy_atmosphere_layer.dart';
import 'magical/starfield_background.dart';

/// Fond commun : **crème** en thème clair, ciel magique en thème sombre.
class LunoraScreenShell extends StatelessWidget {
  const LunoraScreenShell({
    super.key,
    required this.child,
    this.useReaderGradient = false,
    this.showStarfield = false,
    this.starCount = ElunaiLayout.starCount,
    this.joyfulBackdrop = true,
  });

  final Widget child;
  final bool useReaderGradient;
  final bool showStarfield;
  final int starCount;
  final bool joyfulBackdrop;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    if (isLight && !useReaderGradient) {
      return ColoredBox(
        color: LunoraColors.storybookCream,
        child: child,
      );
    }

    final gradient = useReaderGradient
        ? LunoraColors.readerCanvasVertical
        : (joyfulBackdrop ? LunoraColors.joySkyVertical : LunoraColors.nightSkyVertical);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
        if (joyfulBackdrop && !useReaderGradient)
          const Positioned.fill(child: JoyAtmosphereLayer()),
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
