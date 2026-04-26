import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/admin_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/story_universe.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/lunora_badge.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_glass_card.dart';
import '../../../shared/widgets/lunora_night_scaffold.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../../shared/widgets/lunora_section_title.dart';
import '../../../shared/widgets/magical/lunora_progress_bar.dart';
import '../../../shared/widgets/story_ui_labels.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authSessionProvider);
    final child = ref.watch(childProfileProvider);
    final todayStoryAsync = ref.watch(todayStoryProvider);
    final historyAsync = ref.watch(storyHistoryProvider);

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/welcome');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (child == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/setup-child');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final childName = child.firstName.trim().isEmpty
        ? 'ton enfant'
        : child.firstName.trim();
    final theme = Theme.of(context);

    return LunoraNightScaffold(
      scrollable: true,
      joyfulBackdrop: false,
      showStarryOverlay: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: PopupMenuButton<String>(
          icon: Icon(Icons.menu_rounded, color: theme.colorScheme.onSurface),
          onSelected: (value) async {
            if (!context.mounted) return;
            if (value == 'profile') {
              context.push('/setup-child');
              return;
            }
            if (value == 'sub') {
              context.push('/subscription');
              return;
            }
            if (value == 'out') {
              await ref.read(authSessionProvider.notifier).signOut();
              if (context.mounted) context.go('/welcome');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'profile', child: Text('Profil enfant')),
            const PopupMenuItem(value: 'sub', child: Text('Abonnement')),
            const PopupMenuItem(value: 'out', child: Text('Se déconnecter')),
          ],
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Elunai',
              style: theme.textTheme.titleMedium?.copyWith(
                color: LunoraColors.forestGreen,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Histoires pour enfants',
              style: theme.textTheme.bodySmall?.copyWith(
                color: LunoraColors.storybookInkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Réglages',
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => context.push('/setup-child'),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) context.push('/history');
          if (i == 2) context.push('/setup-child');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: 'Bibliothèque',
          ),
          NavigationDestination(
            icon: Icon(Icons.child_care_outlined),
            selectedIcon: Icon(Icons.child_care_rounded),
            label: 'Profil',
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LunoraFadeIn(
            child: _HeroCard(
              childName: childName,
              asyncStory: todayStoryAsync,
              onRetryToday: () => ref.invalidate(todayStoryProvider),
            ),
          ),
          const SizedBox(height: LunoraSpacing.xl),
          LunoraFadeIn(
            delay: const Duration(milliseconds: 80),
            child: _StoryHubCard(
              user: user,
              childProfile: child,
              asyncStory: todayStoryAsync,
              onRead: (story) =>
                  context.push('/story?id=${Uri.encodeComponent(story.id)}'),
              onGenerate: () => context.push('/generate'),
              onAdminRegenerate: () =>
                  _runAdminStoryRegeneration(context, ref, user, child),
            ),
          ),
          const SizedBox(height: LunoraSpacing.xl),
          LunoraFadeIn(
            delay: const Duration(milliseconds: 100),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Dernières histoires',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: LunoraColors.forestGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/history'),
                  child: Text(
                    'Tout voir',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: LunoraColors.forestGreenSoft,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LunoraSpacing.sm),
          SizedBox(
            height: 196,
            child: historyAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: LunoraProgressBar()),
              error: (Object? err, StackTrace? st) => const SizedBox.shrink(),
              data: (hist) {
                final stories = _storiesForStrip(
                  todayStoryAsync.valueOrNull,
                  hist,
                );
                if (stories.isEmpty) {
                  return _PlaceholderStoryStrip();
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: LunoraSpacing.sm),
                  itemCount: stories.length,
                  separatorBuilder: (ctx, i) =>
                      const SizedBox(width: LunoraSpacing.sm),
                  itemBuilder: (context, i) {
                    final s = stories[i];
                    return _StoryCoverCard(
                      story: s,
                      onTap: () => context.push(
                        '/story?id=${Uri.encodeComponent(s.id)}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: LunoraSpacing.lg),
        ],
      ),
    );
  }
}

List<Story> _storiesForStrip(Story? today, List<Story> history) {
  final seen = <String>{};
  final out = <Story>[];
  if (today != null && seen.add(today.id)) {
    out.add(today);
  }
  for (final s in history) {
    if (out.length >= 8) break;
    if (seen.add(s.id)) out.add(s);
  }
  return out;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.childName,
    required this.asyncStory,
    required this.onRetryToday,
  });

  final String childName;
  final AsyncValue<Story?> asyncStory;
  final VoidCallback onRetryToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LunoraColors.heroCardBlue, LunoraColors.heroCardBlueDeep],
        ),
        boxShadow: [
          BoxShadow(
            color: LunoraColors.storybookInk.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(LunoraSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Découvre des histoires magiques ✨',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: LunoraColors.moonIvory,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Pour $childName — une histoire douce chaque soir.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.moonIvory.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.md),
                asyncStory.when(
                  data: (story) {
                    final hint = story != null
                        ? 'L’histoire du jour est un peu plus bas.'
                        : 'Ta prochaine lecture t’attend dans la carte du bas.';
                    return Text(
                      hint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: LunoraColors.moonIvory.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: LunoraColors.honeyYellow,
                        ),
                      ),
                    ),
                  ),
                  error: (Object? e, StackTrace? st) => FilledButton(
                    onPressed: onRetryToday,
                    style: FilledButton.styleFrom(
                      backgroundColor: LunoraColors.honeyYellow,
                      foregroundColor: LunoraColors.storybookInk,
                    ),
                    child: const Text('Réessayer'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LunoraSpacing.md),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: LunoraColors.moonIvory.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: LunoraColors.honeyYellow.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              size: 44,
              color: LunoraColors.honeyYellow,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryCoverCard extends StatelessWidget {
  const _StoryCoverCard({required this.story, required this.onTap});

  static const double _cardHeight = 188;
  static const double _thumbHeight = 118;

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: LunoraColors.storybookSurface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: LunoraColors.storybookInk.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 150,
          height: _cardHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: _thumbHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        LunoraColors.forestGreenSoft.withValues(alpha: 0.35),
                        LunoraColors.storybookCreamDeep.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 40,
                      color: LunoraColors.forestGreen.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: LunoraColors.storybookInk,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderStoryStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final samples = StoryUniverse.values.take(3).toList();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: samples.length,
      separatorBuilder: (ctx, i) => const SizedBox(width: LunoraSpacing.sm),
      itemBuilder: (context, i) {
        final u = samples[i];
        final m = u.meta;
        return Container(
          width: 150,
          height: _StoryCoverCard._cardHeight,
          padding: const EdgeInsets.all(LunoraSpacing.md),
          decoration: BoxDecoration(
            color: LunoraColors.storybookSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: m.accentColor.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.emoji, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Text(
                m.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: LunoraColors.storybookInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bientôt ici',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: LunoraColors.storybookInkMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> _runAdminStoryRegeneration(
  BuildContext context,
  WidgetRef ref,
  UserModel user,
  ChildProfile child,
) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Régénérer l’histoire du jour ?'),
      content: const Text(
        'L’entrée du jour sera supprimée puis une nouvelle histoire sera générée '
        '(possible coût API si la génération distante est activée).',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Régénérer'),
        ),
      ],
    ),
  );
  if (confirm != true || !context.mounted) return;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  try {
    await ref
        .read(storyRepositoryProvider)
        .adminRegenerateTodayStory(user: user, child: child);
    ref.invalidate(todayStoryProvider);
    ref.invalidate(storyHistoryProvider);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Régénération impossible : $e')));
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _StoryHubCard extends StatelessWidget {
  const _StoryHubCard({
    required this.user,
    required this.childProfile,
    required this.asyncStory,
    required this.onRead,
    required this.onGenerate,
    required this.onAdminRegenerate,
  });

  final UserModel user;
  final ChildProfile childProfile;
  final AsyncValue<Story?> asyncStory;
  final void Function(Story story) onRead;
  final VoidCallback onGenerate;
  final VoidCallback onAdminRegenerate;

  @override
  Widget build(BuildContext context) {
    return LunoraGlassCard(
      child: asyncStory.when(
        skipLoadingOnReload: true,
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: LunoraProgressBar()),
        ),
        error: (Object? err, StackTrace? st) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LunoraSectionTitle('Aujourd’hui'),
            const SizedBox(height: LunoraSpacing.sm),
            Text(
              'Impossible de préparer une histoire pour le moment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: LunoraSpacing.md),
            LunoraPrimaryButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: onGenerate,
            ),
            if (AdminConfig.isAdminUser(user)) ...[
              const SizedBox(height: LunoraSpacing.sm),
              TextButton(
                onPressed: onAdminRegenerate,
                child: const Text('Régénérer (admin)'),
              ),
            ],
          ],
        ),
        data: (story) {
          if (story == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LunoraSectionTitle('Aujourd’hui'),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Aucune histoire prête pour le moment.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.md),
                LunoraPrimaryButton(
                  label: 'Créer une histoire',
                  icon: Icons.bedtime_rounded,
                  onPressed: onGenerate,
                ),
              ],
            );
          }

          final childName = childProfile.firstName.trim().isEmpty
              ? 'ton enfant'
              : childProfile.firstName.trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LunoraSectionTitle('Histoire du jour'),
              const SizedBox(height: LunoraSpacing.sm),
              Text(
                story.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: LunoraColors.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: LunoraSpacing.sm),
              Text(
                'Prête pour $childName.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LunoraSpacing.md),
              Wrap(
                spacing: LunoraSpacing.xs,
                runSpacing: LunoraSpacing.xs,
                children: [
                  LunoraBadge(
                    label: readingDurationLabel(story.estimatedReadingMinutes),
                    icon: Icons.timer_outlined,
                  ),
                  LunoraBadge(
                    label: storyFormatLabel(story),
                    icon: Icons.menu_book_rounded,
                  ),
                  LunoraBadge(
                    label: storySourceLabel(story.generationSource),
                    icon: Icons.auto_awesome_rounded,
                  ),
                  if (story.isSerialized)
                    LunoraBadge(
                      label: 'Chapitre ${story.chapterNumber}',
                      icon: Icons.bookmark_rounded,
                    ),
                ],
              ),
              const SizedBox(height: LunoraSpacing.lg),
              LunoraPrimaryButton(
                label: 'Lire l’histoire',
                icon: Icons.play_arrow_rounded,
                onPressed: () => onRead(story),
              ),
              if (AdminConfig.isAdminUser(user)) ...[
                const SizedBox(height: LunoraSpacing.sm),
                TextButton(
                  onPressed: onAdminRegenerate,
                  child: const Text('Régénérer (admin)'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
