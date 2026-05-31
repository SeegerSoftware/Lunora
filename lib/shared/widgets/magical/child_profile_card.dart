import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Avatar + prénom (profil enfant).
class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({
    super.key,
    required this.firstName,
    this.caption = 'Profil enfant personnalisé',
  });

  final String firstName;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmed = firstName.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(ElunaiSpacing.md),
      decoration: BoxDecoration(
        borderRadius: ElunaiSpacing.radiusLg,
        gradient: ElunaiColors.cardAura,
        border: Border.all(color: ElunaiColors.mist.withValues(alpha: 0.14)),
        boxShadow: ElunaiColors.primaryGlow(opacity: 0.12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ElunaiColors.violetGlow.withValues(alpha: 0.55),
                  ElunaiColors.violetSoft.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: ElunaiColors.starGold.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: ElunaiColors.warmBeige,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: ElunaiSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.trim().isEmpty ? '…' : firstName.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ElunaiColors.warmBeige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: ElunaiSpacing.xxs),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ElunaiColors.mist.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.favorite_rounded,
            color: ElunaiColors.starGold.withValues(alpha: 0.55),
            size: 22,
          ),
        ],
      ),
    );
  }
}
