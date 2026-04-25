import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/lunora_badge.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_glass_card.dart';
import '../../../shared/widgets/lunora_night_scaffold.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_section_title.dart';
import '../../../shared/widgets/magical/lunora_progress_bar.dart';
import '../../../shared/widgets/story_ui_labels.dart';
import 'providers/story_providers.dart';

class StoryReaderScreen extends ConsumerStatefulWidget {
  const StoryReaderScreen({super.key, this.storyId});

  final String? storyId;

  @override
  ConsumerState<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends ConsumerState<StoryReaderScreen> {
  double _fontSize = 20;
  static const double _minReaderFontSize = 18;
  static const double _maxReaderFontSize = 24;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final id = widget.storyId;
    final asyncStory = id == null
        ? ref.watch(todayStoryProvider)
        : ref.watch(storyByIdProvider(id));

    return LunoraNightScaffold(
      scrollable: false,
      starCount: 20,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Retour',
          icon: Icon(
            Icons.arrow_back_rounded,
            color: LunoraColors.warmBeige.withValues(alpha: 0.95),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Bonne lecture',
          style: theme.textTheme.titleMedium?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: asyncStory.when(
            skipLoadingOnReload: true,
            data: (story) {
              if (story == null) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppSizes.readerMaxWidth,
                    ),
                    child: LunoraGlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Aucune histoire disponible pour ce soir.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: LunoraColors.warmBeige,
                            ),
                          ),
                          const SizedBox(height: LunoraSpacing.lg),
                          if (id == null)
                            LunoraPrimaryButton(
                              label: 'Préparer l\'histoire de ce soir',
                              icon: Icons.auto_stories_outlined,
                              onPressed: () => ref.invalidate(todayStoryProvider),
                            )
                          else
                            LunoraPrimaryButton(
                              label: 'Ouvrir l\'histoire de ce soir',
                              icon: Icons.nights_stay_rounded,
                              onPressed: () => context.go('/story'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                ),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - 100,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 700),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LunoraFadeIn(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const LunoraSectionTitle('Ce soir'),
                                  const SizedBox(height: LunoraSpacing.sm),
                                  Text(
                                    'Générée avec ${storyModelLabel(story.generationSource)}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: LunoraColors.mist.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: LunoraSpacing.xs),
                                  Text(
                                    story.title,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                      color: LunoraColors.warmBeige,
                                      fontWeight: FontWeight.w800,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: LunoraSpacing.sm),
                                  Wrap(
                                    spacing: LunoraSpacing.xs,
                                    runSpacing: LunoraSpacing.xs,
                                    children: [
                                      LunoraBadge(
                                        icon: Icons.timer_outlined,
                                        label: readingDurationLabel(
                                          story.estimatedReadingMinutes,
                                        ),
                                      ),
                                      LunoraBadge(
                                        icon: Icons.menu_book_rounded,
                                        label: storyFormatLabel(story),
                                      ),
                                      if (story.isSerialized)
                                        LunoraBadge(
                                          icon: Icons.bookmark_rounded,
                                          label: 'Chapitre ${story.chapterNumber}',
                                        ),
                                      LunoraBadge(
                                        icon: Icons.auto_awesome_rounded,
                                        label: storySourceLabel(
                                          story.generationSource,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.md),
                            LunoraFadeIn(
                              delay: const Duration(milliseconds: 120),
                              child: LunoraGlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        _fontAction(
                                          context,
                                          label: 'A-',
                                          onTap: () => setState(() {
                                            _fontSize = (_fontSize - 0.5).clamp(
                                              _minReaderFontSize,
                                              _maxReaderFontSize,
                                            );
                                          }),
                                        ),
                                        const SizedBox(width: LunoraSpacing.xs),
                                        _fontAction(
                                          context,
                                          label: 'A+',
                                          onTap: () => setState(() {
                                            _fontSize = (_fontSize + 0.5).clamp(
                                              _minReaderFontSize,
                                              _maxReaderFontSize,
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: LunoraSpacing.sm),
                                    Text(
                                      'Bonne lecture',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                            color: LunoraColors.mist.withValues(alpha: 0.82),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: LunoraSpacing.md),
                                    ..._paragraphWidgets(context, story.content),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: LunoraSpacing.lg),
                            LunoraPrimaryButton(
                              label: 'Terminer l\'histoire',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () => context.go('/home'),
                            ),
                            const SizedBox(height: LunoraSpacing.md),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: LunoraProgressBar()),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(LunoraSpacing.md),
              child: Center(
                child: LunoraFadeIn(
                  child: LunoraGlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Impossible d’afficher l’histoire.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: LunoraColors.warmBeige,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LunoraSpacing.sm),
                        Text(
                          '$err',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LunoraColors.mist.withValues(alpha: 0.86),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LunoraSpacing.lg),
                        if (id == null)
                          LunoraPrimaryButton(
                            label: 'Réessayer',
                            icon: Icons.refresh_rounded,
                            onPressed: () => ref.invalidate(todayStoryProvider),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _fontAction(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LunoraSpacing.sm + 2,
          vertical: LunoraSpacing.xxs + 3,
        ),
        decoration: BoxDecoration(
          color: LunoraColors.nightBlueLift.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: LunoraColors.starGoldSoft.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: LunoraColors.warmBeige,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }

  List<Widget> _paragraphWidgets(BuildContext context, String content) {
    final paragraphs = content
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: _fontSize,
          height: _lineHeightForFontSize(_fontSize),
          color: LunoraColors.warmBeige.withValues(alpha: 0.97),
        );
    final paragraphGap = _paragraphGapForFontSize(_fontSize);
    return [
      for (var i = 0; i < paragraphs.length; i++) ...[
        Text(paragraphs[i], style: style),
        if (i != paragraphs.length - 1)
          SizedBox(height: paragraphGap),
      ],
    ];
  }

  double _lineHeightForFontSize(double fontSize) {
    final t = ((fontSize - _minReaderFontSize) /
            (_maxReaderFontSize - _minReaderFontSize))
        .clamp(0.0, 1.0);
    // Courbe de confort: texte petit => interligne plus ample.
    return 1.7 - (0.12 * t);
  }

  double _paragraphGapForFontSize(double fontSize) {
    final t = ((fontSize - _minReaderFontSize) /
            (_maxReaderFontSize - _minReaderFontSize))
        .clamp(0.0, 1.0);
    return 20 - (4 * t);
  }
}
