import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/achievement.dart';
import '../../../shared/models/story.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/elunai_fade_in.dart';
import '../../../shared/widgets/elunai_page_header.dart';
import '../../../shared/widgets/elunai_screen_shell.dart';
import '../../../shared/widgets/magical/elunai_progress_bar.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/story_providers.dart';
import 'widgets/library_cards.dart';

enum _LibraryFilter { active, completed, all }

enum _LibrarySort { recent, oldest, title }

class StoryHistoryScreen extends ConsumerStatefulWidget {
  const StoryHistoryScreen({super.key});

  @override
  ConsumerState<StoryHistoryScreen> createState() => _StoryHistoryScreenState();
}

class _StoryHistoryScreenState extends ConsumerState<StoryHistoryScreen> {
  var _filter = _LibraryFilter.active;
  var _sort = _LibrarySort.recent;
  var _query = '';

  @override
  Widget build(BuildContext context) {
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
      appBar: ElunaiAppBar(
        title: 'Bibliothèque',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.safePopOrGo('/home'),
        ),
      ),
      body: ElunaiScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: historyAsync.when(
            skipLoadingOnReload: true,
            data: (stories) {
              final blocks = _visibleBlocks(
                _timelineBlocks(stories),
                filter: _filter,
                sort: _sort,
                query: _query,
              );
              final achievements = AchievementCalculator.earned(stories);
              return ListView(
                padding: ElunaiSpacing.screen.copyWith(
                  bottom: ElunaiSpacing.xxl,
                ),
                children: [
                  const ElunaiFadeIn(
                    child: ElunaiPageHeader(
                      compact: true,
                      icon: Icons.local_library_rounded,
                      title: 'Bibliothèque du soir',
                      subtitle:
                          'Toutes les histoires restent accessibles pour relire, reprendre une série ou retrouver un moment préféré.',
                    ),
                  ),
                  const SizedBox(height: ElunaiSpacing.xl),
                  _LibraryControls(
                    filter: _filter,
                    sort: _sort,
                    onFilterChanged: (value) => setState(() => _filter = value),
                    onSortChanged: (value) => setState(() => _sort = value),
                    onQueryChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: ElunaiSpacing.md),
                  if (achievements.isNotEmpty) ...[
                    _MilestoneCard(achievement: achievements.last),
                    const SizedBox(height: ElunaiSpacing.md),
                  ],
                  if (blocks.isEmpty)
                    const _EmptyLibrary()
                  else
                    ...blocks.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: ElunaiSpacing.md,
                        ),
                        child: ElunaiFadeIn(
                          delay: Duration(
                            milliseconds: 40 * entry.key.clamp(0, 8),
                          ),
                          child: entry.value.isSeries
                              ? _SeriesTimelineTile(
                                  stories: entry.value.stories,
                                  onResume: () => context.push(
                                    '/story?id=${entry.value.stories.first.id}',
                                  ),
                                )
                              : _HistoryStoryTile(
                                  story: entry.value.stories.first,
                                  onTap: () => context.push(
                                    '/story?id=${entry.value.stories.first.id}',
                                  ),
                                ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: ElunaiProgressBar()),
            error: (err, _) => Center(
              child: Padding(
                padding: ElunaiSpacing.screen,
                child: Text(
                  'Impossible de charger la bibliothèque : $err',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
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

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(ElunaiSpacing.md),
      decoration: BoxDecoration(
        color: ElunaiColors.honeyYellow.withValues(alpha: 0.18),
        borderRadius: ElunaiSpacing.radiusLg,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.bookmark_added_rounded,
            color: ElunaiColors.forestGreen,
          ),
          const SizedBox(width: ElunaiSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ElunaiColors.storybookInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: ElunaiColors.storybookInkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(ElunaiSpacing.lg),
      decoration: BoxDecoration(
        color: ElunaiColors.storybookSurface,
        borderRadius: ElunaiSpacing.radiusLg,
        border: Border.all(
          color: ElunaiColors.forestGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            size: 44,
            color: ElunaiColors.forestGreen,
          ),
          const SizedBox(height: ElunaiSpacing.md),
          Text(
            'La première histoire apparaîtra ici',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: ElunaiColors.storybookInk,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: ElunaiSpacing.xs),
          Text(
            'Après la génération, elle sera sauvegardée automatiquement dans cette bibliothèque.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: ElunaiColors.storybookInkMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineBlock {
  const _TimelineBlock({required this.stories, required this.isSeries});

  final List<Story> stories;
  final bool isSeries;

  Story get latest => stories.first;

  bool get isCompleted =>
      isSeries && latest.chapterNumber >= latest.totalChapters;
}

List<_TimelineBlock> _timelineBlocks(List<Story> stories) {
  final blocks = <_TimelineBlock>[];
  final seriesMap = <String, List<Story>>{};

  for (final s in stories) {
    if (s.format == StoryFormat.serializedChapters && s.seriesId != null) {
      seriesMap.putIfAbsent(s.seriesId!, () => []).add(s);
    } else {
      blocks.add(_TimelineBlock(stories: [s], isSeries: false));
    }
  }

  final seriesBlocks = seriesMap.values.map((seriesStories) {
    seriesStories.sort((a, b) => b.chapterNumber.compareTo(a.chapterNumber));
    return _TimelineBlock(stories: seriesStories, isSeries: true);
  }).toList();

  final merged = [...seriesBlocks, ...blocks];
  merged.sort(
    (a, b) => b.stories.first.dateKey.compareTo(a.stories.first.dateKey),
  );
  return merged;
}

List<_TimelineBlock> _visibleBlocks(
  List<_TimelineBlock> blocks, {
  required _LibraryFilter filter,
  required _LibrarySort sort,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final visible = blocks.where((block) {
    final matchesFilter = switch (filter) {
      _LibraryFilter.active => !block.isCompleted,
      _LibraryFilter.completed => block.isCompleted,
      _LibraryFilter.all => true,
    };
    final matchesQuery =
        normalizedQuery.isEmpty ||
        block.stories.any(
          (story) =>
              story.title.toLowerCase().contains(normalizedQuery) ||
              story.summary.toLowerCase().contains(normalizedQuery),
        );
    return matchesFilter && matchesQuery;
  }).toList();
  visible.sort(switch (sort) {
    _LibrarySort.recent => (a, b) => b.latest.dateKey.compareTo(
      a.latest.dateKey,
    ),
    _LibrarySort.oldest => (a, b) => a.latest.dateKey.compareTo(
      b.latest.dateKey,
    ),
    _LibrarySort.title => (a, b) => a.latest.title.compareTo(b.latest.title),
  });
  return visible;
}

class _LibraryControls extends StatelessWidget {
  const _LibraryControls({
    required this.filter,
    required this.sort,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onQueryChanged,
  });

  final _LibraryFilter filter;
  final _LibrarySort sort;
  final ValueChanged<_LibraryFilter> onFilterChanged;
  final ValueChanged<_LibrarySort> onSortChanged;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher un livre ou une histoire',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: ElunaiColors.storybookSurface,
            border: OutlineInputBorder(
              borderRadius: ElunaiSpacing.radiusLg,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: ElunaiSpacing.sm),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<_LibraryFilter>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: _LibraryFilter.active,
                    label: Text('En cours'),
                  ),
                  ButtonSegment(
                    value: _LibraryFilter.completed,
                    label: Text('Terminées'),
                  ),
                  ButtonSegment(
                    value: _LibraryFilter.all,
                    label: Text('Toutes'),
                  ),
                ],
                selected: {filter},
                onSelectionChanged: (values) => onFilterChanged(values.first),
              ),
            ),
            const SizedBox(width: ElunaiSpacing.xs),
            PopupMenuButton<_LibrarySort>(
              tooltip: 'Trier',
              initialValue: sort,
              onSelected: onSortChanged,
              icon: const Icon(Icons.sort_rounded),
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _LibrarySort.recent,
                  child: Text('Plus récentes'),
                ),
                PopupMenuItem(
                  value: _LibrarySort.oldest,
                  child: Text('Plus anciennes'),
                ),
                PopupMenuItem(value: _LibrarySort.title, child: Text('Titre')),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryStoryTile extends StatelessWidget {
  const _HistoryStoryTile({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _LibraryTile(
      icon: Icons.menu_book_rounded,
      title: story.title,
      subtitle: story.summary,
      meta: '${story.dateKey} · ${story.estimatedReadingMinutes} min',
      onTap: onTap,
      progress: null,
      theme: theme,
      coverImageUrl: story.coverImageUrl,
    );
  }
}

class _SeriesTimelineTile extends StatelessWidget {
  const _SeriesTimelineTile({required this.stories, required this.onResume});

  final List<Story> stories;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final latest = stories.first;
    final total = latest.totalChapters <= 0 ? 1 : latest.totalChapters;
    final ratio = (latest.chapterNumber / total).clamp(0.0, 1.0);
    return _LibraryTile(
      icon: Icons.auto_stories_rounded,
      title: latest.title,
      subtitle:
          'Série en chapitres · progression ${latest.chapterNumber}/$total',
      meta: 'Reprendre la série',
      onTap: onResume,
      progress: ratio,
      theme: Theme.of(context),
      coverImageUrl: latest.coverImageUrl,
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.onTap,
    required this.theme,
    this.progress,
    this.coverImageUrl,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;
  final ThemeData theme;
  final double? progress;
  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    return BookCard(
      child: Material(
        color: ElunaiColors.storybookSurface,
        borderRadius: ElunaiSpacing.radiusLg,
        child: InkWell(
          borderRadius: ElunaiSpacing.radiusLg,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(ElunaiSpacing.md),
            decoration: BoxDecoration(
              borderRadius: ElunaiSpacing.radiusLg,
              border: Border.all(
                color: ElunaiColors.forestGreen.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 72,
                  decoration: BoxDecoration(
                    color: ElunaiColors.honeyYellow.withValues(alpha: 0.36),
                    borderRadius: ElunaiSpacing.radiusMd,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: coverImageUrl == null
                      ? Icon(icon, color: ElunaiColors.forestGreen)
                      : Image.network(
                          coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              Icon(icon, color: ElunaiColors.forestGreen),
                        ),
                ),
                const SizedBox(width: ElunaiSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: ElunaiColors.storybookInk,
                          fontWeight: FontWeight.w900,
                          height: 1.22,
                        ),
                      ),
                      const SizedBox(height: ElunaiSpacing.xxs),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ElunaiColors.storybookInkMuted,
                          height: 1.34,
                        ),
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: ElunaiSpacing.sm),
                        SeriesProgressIndicator(
                          currentChapter: (progress! * 1000).round(),
                          totalChapters: 1000,
                        ),
                      ],
                      const SizedBox(height: ElunaiSpacing.sm),
                      Text(
                        meta,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ElunaiColors.forestGreen,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ElunaiColors.storybookInkMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
