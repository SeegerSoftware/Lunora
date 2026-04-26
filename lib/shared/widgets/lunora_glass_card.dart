import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class LunoraGlassCard extends StatelessWidget {
  const LunoraGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LunoraSpacing.lg),
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
            ? LunoraColors.storybookSurface.withValues(alpha: 0.98)
            : LunoraColors.nightBlueDeep.withValues(alpha: 0.38),
        border: Border.all(
          color: light
              ? LunoraColors.forestGreen.withValues(alpha: 0.1)
              : LunoraColors.starGoldSoft.withValues(alpha: 0.14),
        ),
        boxShadow: light
            ? [
                BoxShadow(
                  color: LunoraColors.storybookInk.withValues(alpha: 0.06),
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
                  color: LunoraColors.violetSoft.withValues(alpha: 0.08),
                  blurRadius: 42,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
