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
        borderRadius: ElunaiSpacing.radiusMd,
        onTap: onTap,
        child: Ink(
          width: ElunaiSpacing.storyCardWidth,
          decoration: BoxDecoration(
            borderRadius: ElunaiSpacing.radiusMd,
            gradient: ElunaiColors.cardAura,
            border: Border.all(
              color: ElunaiColors.mist.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: ElunaiColors.violetSoft.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
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
                  height: ElunaiSpacing.storyCardImageHeight,
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
                              ElunaiColors.nightBlueLift,
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.auto_stories_rounded,
                          size: 44,
                          color: ElunaiColors.starGold.withValues(alpha: 0.65),
                        ),
                      ),
                      Positioned(
                        top: ElunaiSpacing.sm,
                        right: ElunaiSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: ElunaiSpacing.sm,
                            vertical: ElunaiSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: ElunaiColors.nightBlue.withValues(
                              alpha: 0.45,
                            ),
                            borderRadius: ElunaiSpacing.radiusSm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 14,
                                color: ElunaiColors.warmBeige.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$readingMinutes min',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: ElunaiColors.warmBeige.withValues(
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
                  ElunaiSpacing.md,
                  ElunaiSpacing.sm,
                  ElunaiSpacing.md,
                  ElunaiSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ElunaiColors.warmBeige,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: ElunaiSpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ElunaiColors.mist.withValues(alpha: 0.75),
                        height: 1.25,
                      ),
                    ),
                    if (chapterLabel != null) ...[
                      const SizedBox(height: ElunaiSpacing.xs),
                      Text(
                        chapterLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ElunaiColors.starGoldSoft.withValues(
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
