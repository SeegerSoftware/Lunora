import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/story.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../../shared/widgets/magical/lunora_progress_bar.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/story_providers.dart';

class StoryHistoryScreen extends ConsumerWidget {
  const StoryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider);
    final historyAsync = ref.watch(storyHistoryProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Historique',
          style: theme.textTheme.titleLarge?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: LunoraColors.warmBeige.withValues(alpha: 0.9),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        starCount: 28,
        child: SafeArea(
          child: historyAsync.when(
            skipLoadingOnReload: true,
            data: (stories) {
              if (stories.isEmpty) {
                return Center(
                  child: Padding(
                    padding: LunoraSpacing.screen,
                    child: LunoraFadeIn(
                      child: Text(
                        'Les histoires générées apparaîtront ici, dans le carnet de lecture.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: LunoraColors.mist.withValues(alpha: 0.82),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: LunoraSpacing.screen.copyWith(
                  top: LunoraSpacing.sm,
                  bottom: LunoraSpacing.xxl,
                ),
                itemCount: _timelineBlocks(stories).length,
                separatorBuilder: (context, _) =>
                    const SizedBox(height: LunoraSpacing.md),
                itemBuilder: (context, index) {
                  final block = _timelineBlocks(stories)[index];
                  return LunoraFadeIn(
                    delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                    child: block.isSeries
                        ? _SeriesTimelineTile(
                            stories: block.stories,
                            onResume: () => context.push('/story?id=${block.stories.first.id}'),
                          )
                        : _HistoryStoryTile(
                            story: block.stories.first,
                            onTap: () => context.push('/story?id=${block.stories.first.id}'),
                          ),
                  );
                },
              );
            },
            loading: () => const Center(child: LunoraProgressBar()),
            error: (err, _) => Center(
              child: Padding(
                padding: LunoraSpacing.screen,
                child: Text(
                  'Erreur : $err',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineBlock {
  const _TimelineBlock({
    required this.stories,
    required this.isSeries,
  });

  final List<Story> stories;
  final bool isSeries;
}

List<_TimelineBlock> _timelineBlocks(List<Story> stories) {
  final blocks = <_TimelineBlock>[];
  final seriesMap = <String, List<Story>>{};

  for (final s in stories) {
    if (s.format == StoryFormat.serializedChapters && s.seriesId != null) {
      seriesMap.putIfAbsent(s.seriesId!, () => []).add(s);
      continue;
    }
    blocks.add(_TimelineBlock(stories: [s], isSeries: false));
  }

  final seriesBlocks = seriesMap.values.map((seriesStories) {
    seriesStories.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
    return _TimelineBlock(stories: seriesStories, isSeries: true);
  }).toList();

  final merged = [...seriesBlocks, ...blocks];
  merged.sort((a, b) => b.stories.first.dateKey.compareTo(a.stories.first.dateKey));
  return merged;
}

class _HistoryStoryTile extends StatelessWidget {
  const _HistoryStoryTile({
    required this.story,
    required this.onTap,
  });

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = '${story.dateKey} · ${story.estimatedReadingMinutes} min';

    return Material(
      color: LunoraColors.nightBlueLift.withValues(alpha: 0.72),
      borderRadius: LunoraSpacing.radiusLg,
      child: InkWell(
        borderRadius: LunoraSpacing.radiusLg,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(LunoraSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: LunoraSpacing.radiusMd,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2B3F68),
                      LunoraColors.nightBlueLift,
                    ],
                  ),
                  border: Border.all(
                    color: LunoraColors.mist.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: LunoraColors.starGold.withValues(alpha: 0.75),
                  size: 24,
                ),
              ),
              const SizedBox(width: LunoraSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      story.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: LunoraColors.warmBeige,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.xs),
                    Text(
                      story.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.75),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.sm),
                    Text(
                      meta,
                      style: LunoraTextStyles.storyReaderMetaOnCard(
                        theme.textTheme,
                      ).copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: LunoraColors.mist.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeriesTimelineTile extends StatelessWidget {
  const _SeriesTimelineTile({
    required this.stories,
    required this.onResume,
  });

  final List<Story> stories;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = stories.first;
    final current = latest.chapterNumber;
    final total = latest.totalChapters;
    final ratio = total <= 0 ? 0.0 : (current / total).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(LunoraSpacing.md),
      decoration: BoxDecoration(
        borderRadius: LunoraSpacing.radiusLg,
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3052), Color(0xFF122546)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: LunoraColors.mist.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: LunoraColors.starGoldSoft),
              const SizedBox(width: LunoraSpacing.xs),
              Expanded(
                child: Text(
                  latest.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: LunoraColors.warmBeige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LunoraSpacing.xs),
          Text(
            'Série en chapitres · progression $current/$total',
            style: theme.textTheme.bodySmall?.copyWith(
              color: LunoraColors.mist.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: LunoraSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: LunoraColors.nightBlueDeep.withValues(alpha: 0.5),
              color: LunoraColors.starGold.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: LunoraSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onResume,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Reprendre la série'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LunoraColors.warmBeige,
                side: BorderSide(color: LunoraColors.mist.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
