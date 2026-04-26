import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'elunai_layout.dart';
import 'joy_atmosphere_layer.dart';
import 'starry_background.dart';

class LunoraNightScaffold extends StatelessWidget {
  const LunoraNightScaffold({
    super.key,
    this.appBar,
    this.scrollable = false,
    this.padding = LunoraSpacing.screen,
    this.starCount = ElunaiLayout.starCount,
    this.joyfulBackdrop = true,
    this.backgroundGradient,
    this.showStarryOverlay = true,
    /// Garde ciel étoilé / nuit même si le thème global est clair (ex. lecteur d’histoire).
    this.forceNightBackdrop = false,
    this.bottomNavigationBar,
    required this.child,
  });

  final PreferredSizeWidget? appBar;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final int starCount;
  final bool joyfulBackdrop;
  final Gradient? backgroundGradient;
  final bool showStarryOverlay;
  final bool forceNightBackdrop;
  final Widget? bottomNavigationBar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final useNight = forceNightBackdrop || !isLight;

    final content = SafeArea(
      child: Padding(
        padding: padding,
        child: scrollable ? SingleChildScrollView(child: child) : child,
      ),
    );

    if (!useNight) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: appBar,
        backgroundColor: LunoraColors.storybookCream,
        body: content,
        bottomNavigationBar: bottomNavigationBar,
      );
    }

    final gradient = backgroundGradient ??
        (joyfulBackdrop ? LunoraColors.joySkyVertical : LunoraColors.nightSkyVertical);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (joyfulBackdrop && backgroundGradient == null)
              const Positioned.fill(child: JoyAtmosphereLayer()),
            Positioned.fill(
              child: showStarryOverlay
                  ? StarryBackground(starCount: starCount, child: content)
                  : content,
            ),
          ],
        ),
      ),
    );
  }
}
