import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class LunoraPageHeader extends StatelessWidget {
  const LunoraPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final titleColor = light
        ? LunoraColors.storybookInk
        : LunoraColors.warmBeige;
    final subtitleColor = light
        ? LunoraColors.storybookInkMuted
        : LunoraColors.mist.withValues(alpha: 0.82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          _HeaderBadge(label: badge!),
          const SizedBox(height: LunoraSpacing.sm),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 44 : 52,
              height: compact ? 44 : 52,
              decoration: BoxDecoration(
                borderRadius: LunoraSpacing.radiusMd,
                color: light
                    ? LunoraColors.honeyYellow.withValues(alpha: 0.46)
                    : LunoraColors.starGoldSoft.withValues(alpha: 0.12),
                border: Border.all(
                  color: light
                      ? LunoraColors.forestGreen.withValues(alpha: 0.14)
                      : LunoraColors.starGoldSoft.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                icon,
                color: light
                    ? LunoraColors.forestGreen
                    : LunoraColors.starGoldSoft,
                size: compact ? 22 : 26,
              ),
            ),
            const SizedBox(width: LunoraSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        (compact
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.displaySmall)
                            ?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: 0,
                            ),
                  ),
                  const SizedBox(height: LunoraSpacing.xs),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: subtitleColor,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: light
            ? LunoraColors.forestGreen.withValues(alpha: 0.08)
            : LunoraColors.mist.withValues(alpha: 0.1),
        border: Border.all(
          color: light
              ? LunoraColors.forestGreen.withValues(alpha: 0.16)
              : LunoraColors.mist.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.sm,
          vertical: LunoraSpacing.xxs + 1,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: light ? LunoraColors.forestGreen : LunoraColors.starGoldSoft,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class LunoraActionTile extends StatelessWidget {
  const LunoraActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final accent = destructive
        ? theme.colorScheme.error
        : LunoraColors.forestGreen;
    final fg = light ? LunoraColors.storybookInk : LunoraColors.warmBeige;
    final meta = light
        ? LunoraColors.storybookInkMuted
        : LunoraColors.mist.withValues(alpha: 0.76);

    return Material(
      color: light
          ? LunoraColors.storybookSurface
          : LunoraColors.nightBlueLift.withValues(alpha: 0.62),
      borderRadius: LunoraSpacing.radiusLg,
      child: InkWell(
        borderRadius: LunoraSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(LunoraSpacing.md),
          decoration: BoxDecoration(
            borderRadius: LunoraSpacing.radiusLg,
            border: Border.all(
              color: destructive
                  ? theme.colorScheme.error.withValues(alpha: 0.24)
                  : (light
                        ? LunoraColors.forestGreen.withValues(alpha: 0.1)
                        : LunoraColors.mist.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: LunoraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: meta,
                        height: 1.34,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: meta.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
