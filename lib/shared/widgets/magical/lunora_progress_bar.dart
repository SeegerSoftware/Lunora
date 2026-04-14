import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Barre de progression « capsule » pour chargements ludiques.
class LunoraProgressBar extends StatelessWidget {
  const LunoraProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: LunoraSpacing.radiusSm,
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          minHeight: 8,
          backgroundColor: LunoraColors.warmBeige.withValues(alpha: 0.08),
          color: LunoraColors.violetGlow,
        ),
      ),
    );
  }
}
