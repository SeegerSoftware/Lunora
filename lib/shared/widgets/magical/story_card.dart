import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';

/// Carte histoire horizontale (aperçu doux, sans image distante MVP).
class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.readingMinutes,
    this.chapterLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int readingMinutes;
  final String? chapterLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: LunoraSpacing.radiusMd,
        onTap: onTap,
        child: Ink(
          width: LunoraSpacing.storyCardWidth,
          decoration: BoxDecoration(
            borderRadius: LunoraSpacing.radiusMd,
            gradient: LunoraColors.cardAura,
            border: Border.all(
              color: LunoraColors.mist.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: LunoraColors.violetSoft.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: LunoraSpacing.storyCardImageHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF2B3F68),
                              LunoraColors.nightBlueLift,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 44,
                          color: LunoraColors.starGold.withValues(alpha: 0.65),
                        ),
                      ),
                      Positioned(
                        top: LunoraSpacing.sm,
                        right: LunoraSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LunoraSpacing.sm,
                            vertical: LunoraSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: LunoraColors.nightBlue.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: LunoraSpacing.radiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: LunoraColors.warmBeige.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$readingMinutes min',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: LunoraColors.warmBeige.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  LunoraSpacing.md,
                  LunoraSpacing.sm,
                  LunoraSpacing.md,
                  LunoraSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: LunoraColors.warmBeige,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.75),
                        height: 1.25,
                      ),
                    ),
                    if (chapterLabel != null) ...[
                      const SizedBox(height: LunoraSpacing.xs),
                      Text(
                        chapterLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: LunoraColors.starGoldSoft.withValues(
                            alpha: 0.85,
                          ),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
