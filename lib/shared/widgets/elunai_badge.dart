import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class ElunaiBadge extends StatelessWidget {
  const ElunaiBadge({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ElunaiSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: light
              ? ElunaiColors.storybookCreamDeep.withValues(alpha: 0.9)
              : ElunaiColors.nightBlue.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: light
                ? ElunaiColors.forestGreen.withValues(alpha: 0.15)
                : ElunaiColors.starGoldSoft.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: light
                    ? ElunaiColors.forestGreen
                    : ElunaiColors.starGoldSoft,
              ),
              const SizedBox(width: ElunaiSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: light
                    ? ElunaiColors.storybookInk
                    : ElunaiColors.warmBeige,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
