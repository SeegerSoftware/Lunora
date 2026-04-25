import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import 'starry_background.dart';

class LunoraNightScaffold extends StatelessWidget {
  const LunoraNightScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.scrollable = false,
    this.padding = LunoraSpacing.screen,
    this.starCount = 36,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final int starCount;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Padding(
        padding: padding,
        child: scrollable ? SingleChildScrollView(child: child) : child,
      ),
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: LunoraColors.nightSkyVertical),
        child: StarryBackground(starCount: starCount, child: content),
      ),
    );
  }
}
