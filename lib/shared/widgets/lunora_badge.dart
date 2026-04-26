import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class LunoraBadge extends StatelessWidget {
  const LunoraBadge({
    super.key,
    required this.label,
    this.icon,
  });

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: light
              ? LunoraColors.storybookCreamDeep.withValues(alpha: 0.9)
              : LunoraColors.nightBlue.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: light
                ? LunoraColors.forestGreen.withValues(alpha: 0.15)
                : LunoraColors.starGoldSoft.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: light ? LunoraColors.forestGreen : LunoraColors.starGoldSoft,
              ),
              const SizedBox(width: LunoraSpacing.xs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: light ? LunoraColors.storybookInk : LunoraColors.warmBeige,
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
