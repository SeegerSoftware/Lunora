import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Avatar + prénom (rituel enfant).
class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({
    super.key,
    required this.firstName,
    this.caption = 'Profil du petit lecteur',
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
      padding: const EdgeInsets.all(LunoraSpacing.md),
      decoration: BoxDecoration(
        borderRadius: LunoraSpacing.radiusLg,
        gradient: LunoraColors.cardAura,
        border: Border.all(color: LunoraColors.mist.withValues(alpha: 0.14)),
        boxShadow: LunoraColors.primaryGlow(opacity: 0.12),
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
                  LunoraColors.violetGlow.withValues(alpha: 0.55),
                  LunoraColors.violetSoft.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: LunoraColors.starGold.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: LunoraColors.warmBeige,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: LunoraSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.trim().isEmpty ? '…' : firstName.trim(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: LunoraColors.warmBeige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.xxs),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: LunoraColors.mist.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.favorite_rounded,
            color: LunoraColors.starGold.withValues(alpha: 0.55),
            size: 22,
          ),
        ],
      ),
    );
  }
}
