import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Barre de progression « capsule » pour chargements ludiques.
class ElunaiProgressBar extends StatelessWidget {
  const ElunaiProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: ElunaiSpacing.radiusSm,
      child: SizedBox(
        height: 8,
        child: LinearProgressIndicator(
          minHeight: 8,
          backgroundColor: ElunaiColors.warmBeige.withValues(alpha: 0.08),
          color: ElunaiColors.violetGlow,
        ),
      ),
    );
  }
}
