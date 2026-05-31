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
import '../../../shared/widgets/elunai_badge.dart';
import '../../../shared/widgets/elunai_fade_in.dart';
import '../../../shared/widgets/elunai_glass_card.dart';
import '../../../shared/widgets/elunai_night_scaffold.dart';
import '../../../shared/widgets/elunai_page_header.dart';
import '../../../shared/widgets/elunai_primary_button.dart';
import '../../../shared/widgets/elunai_section_title.dart';
import '../../../shared/widgets/magical/elunai_progress_bar.dart';
import '../../../shared/widgets/story_ui_labels.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../child_profile/presentation/widgets/child_selector.dart';
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

    return ElunaiNightScaffold(
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
              context.push('/children');
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
            const PopupMenuItem(value: 'profile', child: Text('Mes enfants')),
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
                color: ElunaiColors.forestGreen,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              'Histoires pour enfants',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ElunaiColors.storybookInkMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (AdminConfig.isAdminUser(user))
            PopupMenuButton<String>(
              tooltip: 'Actions administrateur',
              icon: Icon(
                Icons.admin_panel_settings_rounded,
                color: ElunaiColors.forestGreen,
              ),
              onSelected: (value) {
                if (value == 'regenerate_today') {
                  _runAdminStoryRegeneration(context, ref, user, child);
                  return;
                }
                if (value == 'generate_unique') {
                  _runAdminUniqueStoryGeneration(context, ref, user, child);
                  return;
                }
                if (value == 'generate_series') {
                  _runAdminSevenChapterGeneration(context, ref, user, child);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'regenerate_today',
                  child: Text('Régénérer l’histoire du jour'),
                ),
                PopupMenuItem(
                  value: 'generate_unique',
                  child: Text('Nouvelle histoire unique'),
                ),
                PopupMenuItem(
                  value: 'generate_series',
                  child: Text('Histoire complète de 7 chapitres'),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Réglages',
            icon: Icon(
              Icons.settings_outlined,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => context.push('/children'),
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
              ElunaiFadeIn(
                child: ElunaiPageHeader(
                  badge: 'Rituel du soir',
                  icon: Icons.bedtime_rounded,
                  title: 'Bonsoir, $childName',
                  subtitle:
                      'Une histoire personnalisée, une bibliothèque qui grandit, et un rituel simple à reprendre chaque soir.',
                  compact: true,
                ),
              ),
              const SizedBox(height: ElunaiSpacing.sm),
              const Align(
                alignment: Alignment.centerLeft,
                child: ChildSelector(),
              ),
              const SizedBox(height: ElunaiSpacing.lg),
              ElunaiFadeIn(
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
              if (AdminConfig.isAdminUser(user)) ...[
                const SizedBox(height: ElunaiSpacing.md),
                ElunaiFadeIn(
                  delay: const Duration(milliseconds: 75),
                  child: _AdminStoryActionsCard(
                    onGenerateUnique: () => _runAdminUniqueStoryGeneration(
                      context,
                      ref,
                      user,
                      child,
                    ),
                    onGenerateSevenChapters: () =>
                        _runAdminSevenChapterGeneration(
                          context,
                          ref,
                          user,
                          child,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: ElunaiSpacing.md),
              ElunaiFadeIn(
                delay: const Duration(milliseconds: 90),
                child: _QuickActions(
                  onLibrary: () => context.push('/history'),
                  onProfile: () => context.push('/children'),
                  onSubscription: () => context.push('/subscription'),
                ),
              ),
              const SizedBox(height: ElunaiSpacing.xl),
              ElunaiFadeIn(
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
              const SizedBox(height: ElunaiSpacing.lg),
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
        const SizedBox(width: ElunaiSpacing.sm),
        Expanded(
          child: _CompactAction(
            icon: Icons.child_care_rounded,
            label: 'Profil',
            onTap: onProfile,
          ),
        ),
        const SizedBox(width: ElunaiSpacing.sm),
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
      color: ElunaiColors.storybookSurface,
      borderRadius: ElunaiSpacing.radiusMd,
      child: InkWell(
        borderRadius: ElunaiSpacing.radiusMd,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 82),
          padding: const EdgeInsets.symmetric(
            horizontal: ElunaiSpacing.sm,
            vertical: ElunaiSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: ElunaiSpacing.radiusMd,
            border: Border.all(
              color: ElunaiColors.forestGreen.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: ElunaiColors.forestGreen, size: 24),
              const SizedBox(height: ElunaiSpacing.xs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: ElunaiColors.storybookInk,
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
                  color: ElunaiColors.forestGreen,
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
        const SizedBox(height: ElunaiSpacing.sm),
        SizedBox(
          height: 196,
          child: historyAsync.when(
            skipLoadingOnReload: true,
            loading: () => const Center(child: ElunaiProgressBar()),
            error: (Object? err, StackTrace? st) => const SizedBox.shrink(),
            data: (hist) {
              final stories = _storiesForStrip(todayStory, hist);
              if (stories.isEmpty) return _PlaceholderStoryStrip();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: ElunaiSpacing.sm),
                itemCount: stories.length,
                separatorBuilder: (ctx, i) =>
                    const SizedBox(width: ElunaiSpacing.sm),
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
      color: ElunaiColors.storybookSurface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shadowColor: ElunaiColors.storybookInk.withValues(alpha: 0.08),
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
                        ElunaiColors.forestGreenSoft.withValues(alpha: 0.35),
                        ElunaiColors.storybookCreamDeep.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 40,
                      color: ElunaiColors.forestGreen.withValues(alpha: 0.75),
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
                        color: ElunaiColors.storybookInk,
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
      separatorBuilder: (ctx, i) => const SizedBox(width: ElunaiSpacing.sm),
      itemBuilder: (context, i) {
        final u = samples[i];
        final m = u.meta;
        return Container(
          width: 150,
          height: _StoryCoverCard._cardHeight,
          padding: const EdgeInsets.all(ElunaiSpacing.md),
          decoration: BoxDecoration(
            color: ElunaiColors.storybookSurface,
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
                  color: ElunaiColors.storybookInk,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bientôt ici',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ElunaiColors.storybookInkMuted,
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

Future<void> _runAdminUniqueStoryGeneration(
  BuildContext context,
  WidgetRef ref,
  UserModel user,
  ChildProfile child,
) async {
  final confirmed = await _confirmAdminGeneration(
    context: context,
    title: 'Générer une nouvelle histoire unique ?',
    message:
        'Une histoire indépendante sera ajoutée à la bibliothèque sans remplacer '
        'l’histoire du jour. Cette action peut consommer 1 appel IA.',
    confirmLabel: 'Générer',
  );
  if (!confirmed || !context.mounted) return;

  await _runAdminGeneration(
    context: context,
    ref: ref,
    generate: () => ref
        .read(storyRepositoryProvider)
        .adminGenerateUniqueStory(user: user, child: child),
    onSuccess: (story) {
      if (context.mounted) {
        context.push('/story?id=${Uri.encodeComponent(story.id)}');
      }
    },
  );
}

Future<void> _runAdminSevenChapterGeneration(
  BuildContext context,
  WidgetRef ref,
  UserModel user,
  ChildProfile child,
) async {
  final confirmed = await _confirmAdminGeneration(
    context: context,
    title: 'Générer une histoire complète en 7 chapitres ?',
    message:
        'Les 7 chapitres seront générés et archivés immédiatement. Cette action '
        'peut consommer environ 8 appels IA : 1 bible de série et 7 chapitres.',
    confirmLabel: 'Générer les 7 chapitres',
  );
  if (!confirmed || !context.mounted) return;

  await _runAdminGeneration(
    context: context,
    ref: ref,
    generate: () => ref
        .read(storyRepositoryProvider)
        .adminGenerateSevenChapterStory(user: user, child: child),
    onSuccess: (stories) {
      if (!context.mounted || stories.isEmpty) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les 7 chapitres ont été générés.')),
      );
      context.push('/story?id=${Uri.encodeComponent(stories.first.id)}');
    },
  );
}

Future<bool> _confirmAdminGeneration({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> _runAdminGeneration<T>({
  required BuildContext context,
  required WidgetRef ref,
  required Future<T> Function() generate,
  required void Function(T value) onSuccess,
}) async {
  T? result;
  var succeeded = false;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  try {
    result = await generate();
    ref.invalidate(storyHistoryProvider);
    succeeded = true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Génération impossible : $e')));
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
  if (succeeded && context.mounted) onSuccess(result as T);
}

class _AdminStoryActionsCard extends StatelessWidget {
  const _AdminStoryActionsCard({
    required this.onGenerateUnique,
    required this.onGenerateSevenChapters,
  });

  final VoidCallback onGenerateUnique;
  final VoidCallback onGenerateSevenChapters;

  @override
  Widget build(BuildContext context) {
    return ElunaiGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ElunaiSectionTitle('Actions administrateur'),
          const SizedBox(height: ElunaiSpacing.xs),
          Text(
            'Générations de test conservées dans la bibliothèque.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: ElunaiSpacing.md),
          ElunaiPrimaryButton(
            label: 'Générer une nouvelle histoire unique',
            icon: Icons.auto_awesome_rounded,
            onPressed: onGenerateUnique,
          ),
          const SizedBox(height: ElunaiSpacing.sm),
          OutlinedButton.icon(
            onPressed: onGenerateSevenChapters,
            icon: const Icon(Icons.library_books_rounded),
            label: const Text('Générer une histoire de 7 chapitres'),
          ),
        ],
      ),
    );
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
    return ElunaiGlassCard(
      child: asyncStory.when(
        skipLoadingOnReload: true,
        loading: () => const SizedBox(
          height: 120,
          child: Center(child: ElunaiProgressBar()),
        ),
        error: (Object? err, StackTrace? st) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ElunaiSectionTitle('Histoire du soir'),
            const SizedBox(height: ElunaiSpacing.sm),
            Text(
              'Impossible de préparer une histoire pour le moment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: ElunaiSpacing.md),
            ElunaiPrimaryButton(
              label: 'Réessayer',
              icon: Icons.refresh_rounded,
              onPressed: onGenerate,
            ),
            if (AdminConfig.isAdminUser(user)) ...[
              const SizedBox(height: ElunaiSpacing.sm),
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
                const ElunaiSectionTitle('Histoire du soir'),
                const SizedBox(height: ElunaiSpacing.sm),
                Text(
                  'La prochaine histoire sera préparée automatiquement à midi, juste à temps pour le rituel du soir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: ElunaiSpacing.md),
                ElunaiPrimaryButton(
                  label: 'Préparer maintenant',
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
                  const Expanded(child: ElunaiSectionTitle('Prête à lire')),
                  Icon(
                    Icons.nights_stay_rounded,
                    color: ElunaiColors.forestGreen.withValues(alpha: 0.78),
                  ),
                ],
              ),
              const SizedBox(height: ElunaiSpacing.sm),
              Text(
                story.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ElunaiColors.forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: ElunaiSpacing.sm),
              Text(
                'Pour $childName · lecture calme de ${story.estimatedReadingMinutes} min.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: ElunaiSpacing.md),
              Wrap(
                spacing: ElunaiSpacing.xs,
                runSpacing: ElunaiSpacing.xs,
                children: [
                  ElunaiBadge(
                    label: readingDurationLabel(story.estimatedReadingMinutes),
                    icon: Icons.timer_outlined,
                  ),
                  ElunaiBadge(
                    label: storyFormatLabel(story),
                    icon: Icons.menu_book_rounded,
                  ),
                  ElunaiBadge(
                    label: storySourceLabel(story.generationSource),
                    icon: Icons.auto_awesome_rounded,
                  ),
                  if (story.isSerialized)
                    ElunaiBadge(
                      label: 'Chapitre ${story.chapterNumber}',
                      icon: Icons.bookmark_rounded,
                    ),
                ],
              ),
              const SizedBox(height: ElunaiSpacing.lg),
              ElunaiPrimaryButton(
                label: 'Commencer la lecture',
                icon: Icons.play_arrow_rounded,
                onPressed: () => onRead(story),
              ),
              if (AdminConfig.isAdminUser(user)) ...[
                const SizedBox(height: ElunaiSpacing.sm),
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
