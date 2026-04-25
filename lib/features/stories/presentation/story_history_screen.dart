import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
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
                        'Les histoires lues apparaîtront ici, dans un joli carnet de nuit.',
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
                itemCount: stories.length,
                separatorBuilder: (context, _) =>
                    const SizedBox(height: LunoraSpacing.md),
                itemBuilder: (context, index) {
                  final story = stories[index];
                  return LunoraFadeIn(
                    delay: Duration(milliseconds: 40 * index.clamp(0, 8)),
                    child: _HistoryStoryTile(
                      story: story,
                      onTap: () => context.push('/story?id=${story.id}'),
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
