import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class ElunaiGlassCard extends StatelessWidget {
  const ElunaiGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(ElunaiSpacing.lg),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(28)),
        color: light
            ? ElunaiColors.storybookSurface.withValues(alpha: 0.98)
            : ElunaiColors.nightBlueDeep.withValues(alpha: 0.38),
        border: Border.all(
          color: light
              ? ElunaiColors.forestGreen.withValues(alpha: 0.1)
              : ElunaiColors.starGoldSoft.withValues(alpha: 0.14),
        ),
        boxShadow: light
            ? [
                BoxShadow(
                  color: ElunaiColors.storybookInk.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
                BoxShadow(
                  color: ElunaiColors.violetSoft.withValues(alpha: 0.08),
                  blurRadius: 42,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
