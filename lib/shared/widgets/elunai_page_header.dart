import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';

class ElunaiPageHeader extends StatelessWidget {
  const ElunaiPageHeader({
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
        ? ElunaiColors.storybookInk
        : ElunaiColors.warmBeige;
    final subtitleColor = light
        ? ElunaiColors.storybookInkMuted
        : ElunaiColors.mist.withValues(alpha: 0.82);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badge != null) ...[
          _HeaderBadge(label: badge!),
          const SizedBox(height: ElunaiSpacing.sm),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: compact ? 44 : 52,
              height: compact ? 44 : 52,
              decoration: BoxDecoration(
                borderRadius: ElunaiSpacing.radiusMd,
                color: light
                    ? ElunaiColors.honeyYellow.withValues(alpha: 0.46)
                    : ElunaiColors.starGoldSoft.withValues(alpha: 0.12),
                border: Border.all(
                  color: light
                      ? ElunaiColors.forestGreen.withValues(alpha: 0.14)
                      : ElunaiColors.starGoldSoft.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                icon,
                color: light
                    ? ElunaiColors.forestGreen
                    : ElunaiColors.starGoldSoft,
                size: compact ? 22 : 26,
              ),
            ),
            const SizedBox(width: ElunaiSpacing.md),
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
                  const SizedBox(height: ElunaiSpacing.xs),
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
            ? ElunaiColors.forestGreen.withValues(alpha: 0.08)
            : ElunaiColors.mist.withValues(alpha: 0.1),
        border: Border.all(
          color: light
              ? ElunaiColors.forestGreen.withValues(alpha: 0.16)
              : ElunaiColors.mist.withValues(alpha: 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ElunaiSpacing.sm,
          vertical: ElunaiSpacing.xxs + 1,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: light ? ElunaiColors.forestGreen : ElunaiColors.starGoldSoft,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class ElunaiActionTile extends StatelessWidget {
  const ElunaiActionTile({
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
        : ElunaiColors.forestGreen;
    final fg = light ? ElunaiColors.storybookInk : ElunaiColors.warmBeige;
    final meta = light
        ? ElunaiColors.storybookInkMuted
        : ElunaiColors.mist.withValues(alpha: 0.76);

    return Material(
      color: light
          ? ElunaiColors.storybookSurface
          : ElunaiColors.nightBlueLift.withValues(alpha: 0.62),
      borderRadius: ElunaiSpacing.radiusLg,
      child: InkWell(
        borderRadius: ElunaiSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(ElunaiSpacing.md),
          decoration: BoxDecoration(
            borderRadius: ElunaiSpacing.radiusLg,
            border: Border.all(
              color: destructive
                  ? theme.colorScheme.error.withValues(alpha: 0.24)
                  : (light
                        ? ElunaiColors.forestGreen.withValues(alpha: 0.1)
                        : ElunaiColors.mist.withValues(alpha: 0.12)),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 24),
              const SizedBox(width: ElunaiSpacing.md),
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
                    const SizedBox(height: ElunaiSpacing.xxs),
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
