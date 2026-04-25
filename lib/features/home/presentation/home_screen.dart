import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/admin_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/story.dart';
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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final childName = child.firstName.trim().isEmpty ? 'ton enfant' : child.firstName.trim();

    return LunoraNightScaffold(
      scrollable: true,
      starCount: 30,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: LunoraSpacing.sm),
            child: IconButton(
              tooltip: 'Se déconnecter',
              onPressed: () async {
                await ref.read(authSessionProvider.notifier).signOut();
                if (context.mounted) context.go('/welcome');
              },
              icon: Icon(
                Icons.logout_rounded,
                color: LunoraColors.warmBeige.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LunoraFadeIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonsoir',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: LunoraColors.warmBeige,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: LunoraSpacing.xs),
                Text(
                  'Ce soir pour $childName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: LunoraColors.mist,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Un moment doux à partager avant de dormir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.82),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LunoraSpacing.xl),
          LunoraFadeIn(
            delay: const Duration(milliseconds: 120),
            child: _TodayHeroCard(
              user: user,
              childProfile: child,
              asyncStory: todayStoryAsync,
              onRead: (story) => context.push(
                '/story?id=${Uri.encodeComponent(story.id)}',
              ),
              onGenerate: () => ref.invalidate(todayStoryProvider),
              onAdminRegenerate: () => _runAdminStoryRegeneration(
                context,
                ref,
                user,
                child,
              ),
            ),
          ),
          const SizedBox(height: LunoraSpacing.xxl),
          LunoraSectionTitle('Dernières histoires'),
          const SizedBox(height: LunoraSpacing.sm),
          LunoraFadeIn(
            delay: const Duration(milliseconds: 200),
            child: historyAsync.when(
              skipLoadingOnReload: true,
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: LunoraSpacing.lg),
                child: Center(child: LunoraProgressBar()),
              ),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (stories) {
                final others = _otherStories(stories, todayStoryAsync.valueOrNull)
                    .take(3)
                    .toList();
                if (others.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: LunoraSpacing.md),
                    child: Text(
                      'Les prochaines histoires apparaîtront ici.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: LunoraColors.mist.withValues(alpha: 0.74),
                          ),
                    ),
                  );
                }
                return Column(
                  children: others
                      .map(
                        (story) => Padding(
                          padding: const EdgeInsets.only(bottom: LunoraSpacing.sm),
                          child: _HistoryItem(
                            story: story,
                            onTap: () => context.push(
                              '/story?id=${Uri.encodeComponent(story.id)}',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          const SizedBox(height: LunoraSpacing.xxl),
          LunoraSectionTitle('Accès rapides'),
          const SizedBox(height: LunoraSpacing.sm),
          Wrap(
            spacing: LunoraSpacing.sm,
            runSpacing: LunoraSpacing.sm,
            children: [
              _QuickAction(
                icon: Icons.family_restroom_rounded,
                label: 'Espace parent',
                onTap: () => context.push('/parent'),
              ),
              _QuickAction(
                icon: Icons.history_rounded,
                label: 'Historique',
                onTap: () => context.push('/history'),
              ),
              _QuickAction(
                icon: Icons.child_care_rounded,
                label: 'Profil enfant',
                onTap: () => context.push('/setup-child'),
              ),
              _QuickAction(
                icon: Icons.workspace_premium_rounded,
                label: 'Abonnement',
                onTap: () => context.push('/subscription'),
              ),
            ],
          ),
          const SizedBox(height: LunoraSpacing.xl),
        ],
      ),
    );
  }
}

List<Story> _otherStories(List<Story> all, Story? today) {
  if (today == null) return all.take(12).toList();
  return all.where((s) => s.id != today.id).take(12).toList();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Régénération impossible : $e')),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _TodayHeroCard extends StatelessWidget {
  const _TodayHeroCard({
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
          height: 150,
          child: Center(child: LunoraProgressBar()),
        ),
        error: (err, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LunoraSectionTitle('Histoire du jour'),
            const SizedBox(height: LunoraSpacing.sm),
            Text(
              'Impossible de préparer l\'histoire de ce soir.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.warmBeige,
                  ),
            ),
            const SizedBox(height: LunoraSpacing.md),
            LunoraPrimaryButton(
              label: 'Préparer l\'histoire de ce soir',
              icon: Icons.auto_stories_outlined,
              onPressed: onGenerate,
            ),
            if (AdminConfig.isAdminUser(user)) ...[
              const SizedBox(height: LunoraSpacing.sm),
              LunoraPrimaryButton(
                label: 'Régénérer (admin)',
                expand: false,
                onPressed: onAdminRegenerate,
              ),
            ],
          ],
        ),
        data: (story) {
          if (story == null) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LunoraSectionTitle('Histoire du jour'),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Aucune histoire prête pour ce soir.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: LunoraSpacing.md),
                LunoraPrimaryButton(
                  label: 'Créer l\'histoire de ce soir',
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
                      color: LunoraColors.warmBeige,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: LunoraSpacing.sm),
              Text(
                'Créée spécialement pour $childName.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LunoraColors.mist.withValues(alpha: 0.86),
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
                label: 'Lire l\'histoire',
                icon: Icons.play_arrow_rounded,
                onPressed: () => onRead(story),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: LunoraColors.nightBlueLift.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: LunoraColors.mist.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(LunoraSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: LunoraColors.warmBeige,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: LunoraSpacing.xxs),
                      Text(
                        '${story.dateKey} · ${readingDurationLabel(story.estimatedReadingMinutes)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: LunoraColors.mist.withValues(alpha: 0.78),
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: LunoraColors.mist.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = ((constraints.maxWidth - LunoraSpacing.sm) / 2)
            .clamp(140.0, 240.0);
        return SizedBox(
          width: width,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Ink(
                decoration: BoxDecoration(
                  color: LunoraColors.nightBlue.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: LunoraColors.mist.withValues(alpha: 0.14),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LunoraSpacing.md,
                    vertical: LunoraSpacing.sm + 2,
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: LunoraColors.starGoldSoft, size: 18),
                      const SizedBox(width: LunoraSpacing.xs),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: LunoraColors.warmBeige,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
