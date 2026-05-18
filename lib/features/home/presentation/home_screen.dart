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
import '../../../shared/widgets/lunora_page_header.dart';
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LunoraFadeIn(
                child: LunoraPageHeader(
                  badge: 'Rituel du soir',
                  icon: Icons.bedtime_rounded,
                  title: 'Bonsoir, $childName',
                  subtitle:
                      'Une histoire personnalisée, une bibliothèque qui grandit, et un rituel simple à reprendre chaque soir.',
                  compact: true,
                ),
              ),
              const SizedBox(height: LunoraSpacing.lg),
              LunoraFadeIn(
                delay: const Duration(milliseconds: 60),
                child: _StoryHubCard(
                  user: user,
                  childProfile: child,
                  asyncStory: todayStoryAsync,
                  onRead: (story) => context.push(
                    '/story?id=${Uri.encodeComponent(story.id)}',
                  ),
                  onGenerate: () => context.push('/generate'),
                  onAdminRegenerate: () =>
                      _runAdminStoryRegeneration(context, ref, user, child),
                ),
              ),
              const SizedBox(height: LunoraSpacing.md),
              LunoraFadeIn(
                delay: const Duration(milliseconds: 90),
                child: _QuickActions(
                  onLibrary: () => context.push('/history'),
                  onProfile: () => context.push('/setup-child'),
                  onSubscription: () => context.push('/subscription'),
                ),
              ),
              const SizedBox(height: LunoraSpacing.xl),
              LunoraFadeIn(
                delay: const Duration(milliseconds: 120),
                child: _RecentStoriesSection(
                  historyAsync: historyAsync,
                  todayStory: todayStoryAsync.valueOrNull,
                  onOpenLibrary: () => context.push('/history'),
                  onOpenStory: (story) => context.push(
                    '/story?id=${Uri.encodeComponent(story.id)}',
                  ),
                ),
              ),
              const SizedBox(height: LunoraSpacing.lg),
            ],
          ),
        ),
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onLibrary,
    required this.onProfile,
    required this.onSubscription,
  });

  final VoidCallback onLibrary;
  final VoidCallback onProfile;
  final VoidCallback onSubscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactAction(
            icon: Icons.local_library_rounded,
            label: 'Bibliothèque',
            onTap: onLibrary,
          ),
        ),
        const SizedBox(width: LunoraSpacing.sm),
        Expanded(
          child: _CompactAction(
            icon: Icons.child_care_rounded,
            label: 'Profil',
            onTap: onProfile,
          ),
        ),
        const SizedBox(width: LunoraSpacing.sm),
        Expanded(
          child: _CompactAction(
            icon: Icons.workspace_premium_rounded,
            label: 'Abonnement',
            onTap: onSubscription,
          ),
        ),
      ],
    );
  }
}

class _CompactAction extends StatelessWidget {
  const _CompactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: LunoraColors.storybookSurface,
      borderRadius: LunoraSpacing.radiusMd,
      child: InkWell(
        borderRadius: LunoraSpacing.radiusMd,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.sm,
            vertical: LunoraSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: LunoraSpacing.radiusMd,
            border: Border.all(
              color: LunoraColors.forestGreen.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: LunoraColors.forestGreen, size: 24),
              const SizedBox(height: LunoraSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: LunoraColors.storybookInk,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentStoriesSection extends StatelessWidget {
  const _RecentStoriesSection({
    required this.historyAsync,
    required this.todayStory,
    required this.onOpenLibrary,
    required this.onOpenStory,
  });

  final AsyncValue<List<Story>> historyAsync;
  final Story? todayStory;
  final VoidCallback onOpenLibrary;
  final void Function(Story story) onOpenStory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
              onPressed: onOpenLibrary,
              child: const Text('Tout voir'),
            ),
          ],
        ),
        const SizedBox(height: LunoraSpacing.sm),
        SizedBox(
          height: 196,
          child: historyAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: LunoraProgressBar()),
            error: (Object? err, StackTrace? st) => const SizedBox.shrink(),
            data: (hist) {
              final stories = _storiesForStrip(todayStory, hist);
              if (stories.isEmpty) return _PlaceholderStoryStrip();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: LunoraSpacing.sm),
                itemCount: stories.length,
                separatorBuilder: (ctx, i) =>
                    const SizedBox(width: LunoraSpacing.sm),
                itemBuilder: (context, i) {
                  final story = stories[i];
                  return _StoryCoverCard(
                    story: story,
                    onTap: () => onOpenStory(story),
                  );
                },
              );
            },
          ),
        ),
      ],
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
            const LunoraSectionTitle('Histoire du soir'),
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
                const LunoraSectionTitle('Histoire du soir'),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Aucune histoire prête pour le moment. Lance une génération quand le profil est prêt.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.md),
                LunoraPrimaryButton(
                  label: 'Créer l’histoire du soir',
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
              Row(
                children: [
                  const Expanded(child: LunoraSectionTitle('Prête à lire')),
                  Icon(
                    Icons.nights_stay_rounded,
                    color: LunoraColors.forestGreen.withValues(alpha: 0.78),
                  ),
                ],
              ),
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
                'Pour $childName · lecture calme de ${story.estimatedReadingMinutes} min.',
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
                label: 'Commencer la lecture',
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
