import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/widgets/magical/magical.dart';
import 'providers/story_providers.dart';

class StoryReaderScreen extends ConsumerWidget {
  const StoryReaderScreen({super.key, this.storyId});

  final String? storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final id = storyId;
    final asyncStory = id == null
        ? ref.watch(todayStoryProvider)
        : ref.watch(storyByIdProvider(id));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Lecture',
          style: theme.textTheme.titleMedium?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close_rounded,
            color: LunoraColors.warmBeige.withValues(alpha: 0.9),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LunoraColors.nightSkyVertical),
          ),
          StarfieldBackground(
            starCount: 32,
            child: SafeArea(
              child: asyncStory.when(
                skipLoadingOnReload: true,
                data: (story) {
                  if (story == null) {
                    return Padding(
                      padding: AppSizes.screenPadding,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.readerMaxWidth,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Aucune histoire à lire pour le moment.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: LunoraColors.warmBeige,
                                ),
                              ),
                              const SizedBox(height: LunoraSpacing.md),
                              if (id == null)
                                MagicalAppButton(
                                  label: 'Générer ou actualiser',
                                  icon: Icons.auto_stories_outlined,
                                  onPressed: () =>
                                      ref.invalidate(todayStoryProvider),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final chapterLine = story.isSerialized
                      ? 'Chapitre ${story.chapterNumber} / ${story.totalChapters}'
                      : 'Histoire complète';

                  return ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: LunoraSpacing.reader,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.readerMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const AudioPlayerWidget(),
                              const SizedBox(height: LunoraSpacing.xl),
                              Text(
                                story.title,
                                style: AppTheme.storyReaderTitle(
                                  theme.textTheme,
                                ),
                              ),
                              const SizedBox(height: LunoraSpacing.sm),
                              Text(
                                chapterLine,
                                style: AppTheme.storyReaderChapterMeta(
                                  theme.textTheme,
                                ),
                              ),
                              const SizedBox(height: LunoraSpacing.md),
                              Wrap(
                                spacing: LunoraSpacing.sm,
                                runSpacing: LunoraSpacing.xs,
                                children: [
                                  Chip(
                                    label: Text(
                                      '${story.estimatedReadingMinutes} min',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color:
                                                colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    backgroundColor: LunoraColors.violetMuted
                                        .withValues(alpha: 0.55),
                                    side: BorderSide.none,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: LunoraSpacing.sm,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: LunoraSpacing.xl),
                              Text(
                                story.content,
                                style: AppTheme.storyReaderBody(
                                  theme.textTheme,
                                ),
                              ),
                              const SizedBox(height: LunoraSpacing.xxl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Padding(
                  padding: AppSizes.screenPadding,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                            color: LunoraColors.mist.withValues(alpha: 0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: LunoraSpacing.lg),
                        if (id == null)
                          MagicalAppButton(
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
        ],
      ),
    );
  }
}
