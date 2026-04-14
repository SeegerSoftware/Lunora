import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/admin_config.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/magical/magical.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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

    final firstName = child.firstName.trim();
    final greetingName = firstName.isEmpty ? 'petit lecteur' : firstName;

    final planLabel = user.selectedPlan == null
        ? 'Non abonné'
        : 'Plan actif : ${user.selectedPlan}';

    final statusLabel = switch (user.subscriptionStatus) {
      SubscriptionStatus.active => 'Abonnement actif',
      SubscriptionStatus.none => 'Essai / non abonné',
      SubscriptionStatus.grace => 'Période de grâce',
      SubscriptionStatus.canceled => 'Abonnement arrêté',
    };

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: MoonHeader(
          title: 'Ce soir',
          subtitle: 'Un moment doux à partager',
          trailing: IconButton(
            tooltip: 'Se déconnecter',
            style: IconButton.styleFrom(
              backgroundColor: LunoraColors.nightBlueLift.withValues(
                alpha: 0.55,
              ),
            ),
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
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LunoraColors.nightSkyVertical),
          ),
          StarfieldBackground(
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: LunoraSpacing.screen.copyWith(
                      top: LunoraSpacing.sm,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          'Bonsoir $greetingName,',
                          style: LunoraTextStyles.greetingNight(
                            theme.textTheme,
                          ),
                        ),
                        const SizedBox(height: LunoraSpacing.xs),
                        Text(
                          'prêt pour une histoire ?',
                          style: LunoraTextStyles.greetingSub(theme.textTheme),
                        ),
                        const SizedBox(height: LunoraSpacing.xl),
                        _TodayStoryPanel(
                          user: user,
                          child: child,
                          todayStoryAsync: todayStoryAsync,
                          theme: theme,
                          ref: ref,
                        ),
                        const SizedBox(height: LunoraSpacing.xl),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Autres histoires',
                                style: LunoraTextStyles.sectionTitle(
                                  theme.textTheme,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.push('/history'),
                              child: Text(
                                'Tout voir',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: LunoraColors.violetGlow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: LunoraSpacing.sm),
                        SizedBox(
                          height: 268,
                          child: historyAsync.when(
                            skipLoadingOnReload: true,
                            data: (stories) {
                              final today = todayStoryAsync.valueOrNull;
                              final others = _otherStories(stories, today);
                              if (others.isEmpty) {
                                return Center(
                                  child: Text(
                                    'Les histoires passées apparaîtront ici.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: LunoraColors.mist.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: others.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(width: LunoraSpacing.md),
                                itemBuilder: (context, index) {
                                  final s = others[index];
                                  return StoryCard(
                                    title: s.title,
                                    subtitle: s.summary,
                                    readingMinutes: s.estimatedReadingMinutes,
                                    chapterLabel: s.isSerialized
                                        ? 'Ch. ${s.chapterNumber}/${s.totalChapters}'
                                        : null,
                                    onTap: () => context.push(
                                      '/story?id=${Uri.encodeComponent(s.id)}',
                                    ),
                                  );
                                },
                              );
                            },
                            loading: () =>
                                const Center(child: LunoraProgressBar()),
                            error: (e, _) => Center(
                              child: Text(
                                'Historique indisponible.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: LunoraSpacing.xl),
                        Text(
                          'Espace parent',
                          style: LunoraTextStyles.sectionTitle(theme.textTheme),
                        ),
                        const SizedBox(height: LunoraSpacing.sm),
                        _HomeTile(
                          icon: Icons.family_restroom_rounded,
                          title: 'Tableau de bord',
                          subtitle: 'Suivi des lectures et réglages',
                          onTap: () => context.push('/parent'),
                        ),
                        _HomeTile(
                          icon: Icons.history_rounded,
                          title: 'Historique',
                          subtitle: 'Relire les histoires passées',
                          onTap: () => context.push('/history'),
                        ),
                        _HomeTile(
                          icon: Icons.child_care_rounded,
                          title: 'Profil enfant',
                          subtitle: 'Ajuster les préférences',
                          onTap: () => context.push('/setup-child'),
                        ),
                        _HomeTile(
                          icon: Icons.workspace_premium_rounded,
                          title: 'Abonnement',
                          subtitle: '$planLabel · $statusLabel',
                          onTap: () => context.push('/subscription'),
                        ),
                        const SizedBox(height: LunoraSpacing.xxl),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

class _TodayStoryPanel extends StatelessWidget {
  const _TodayStoryPanel({
    required this.user,
    required this.child,
    required this.todayStoryAsync,
    required this.theme,
    required this.ref,
  });

  final UserModel user;
  final ChildProfile child;
  final AsyncValue<Story?> todayStoryAsync;
  final ThemeData theme;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(LunoraSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: LunoraSpacing.radiusLg,
        gradient: LunoraColors.cardAura,
        border: Border.all(color: LunoraColors.mist.withValues(alpha: 0.14)),
        boxShadow: LunoraColors.primaryGlow(opacity: 0.22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.nights_stay_rounded,
                color: LunoraColors.starGold.withValues(alpha: 0.85),
                size: 22,
              ),
              const SizedBox(width: LunoraSpacing.sm),
              Expanded(
                child: Text(
                  'Histoire du jour',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: LunoraColors.warmBeige,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (AdminConfig.isAdminUser(user))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: LunoraSpacing.sm,
                    vertical: LunoraSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: LunoraColors.starGold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LunoraColors.starGold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    'Admin',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: LunoraColors.starGold.withValues(alpha: 0.95),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LunoraSpacing.md),
          todayStoryAsync.when(
            skipLoadingOnReload: true,
            data: (story) {
              if (story == null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Aucune histoire n’est encore disponible pour aujourd’hui.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.82),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: LunoraSpacing.lg),
                    MagicalAppButton(
                      label: 'Générer l’histoire',
                      icon: Icons.auto_stories_outlined,
                      onPressed: () => ref.invalidate(todayStoryProvider),
                    ),
                    if (AdminConfig.isAdminUser(user)) ...[
                      const SizedBox(height: LunoraSpacing.md),
                      MagicalAppButton(
                        variant: MagicalButtonVariant.secondary,
                        label: 'Générer (admin · ignore le cache)',
                        icon: Icons.build_circle_outlined,
                        onPressed: () => _runAdminStoryRegeneration(
                          context,
                          ref,
                          user,
                          child,
                        ),
                      ),
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: LunoraColors.warmBeige,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: LunoraSpacing.sm),
                  Text(
                    story.summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: LunoraColors.mist.withValues(alpha: 0.78),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: LunoraSpacing.md),
                  Wrap(
                    spacing: LunoraSpacing.md,
                    runSpacing: LunoraSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MetaChip(
                        icon: Icons.timer_outlined,
                        label: '${story.estimatedReadingMinutes} min',
                      ),
                      if (story.isSerialized)
                        _MetaChip(
                          icon: Icons.menu_book_rounded,
                          label:
                              'Chapitre ${story.chapterNumber}/${story.totalChapters}',
                        ),
                    ],
                  ),
                  const SizedBox(height: LunoraSpacing.lg),
                  MagicalAppButton(
                    label: 'Lire l’histoire',
                    icon: Icons.menu_book_rounded,
                    onPressed: () => context.push('/story'),
                  ),
                  if (AdminConfig.isAdminUser(user)) ...[
                    const SizedBox(height: LunoraSpacing.md),
                    MagicalAppButton(
                      variant: MagicalButtonVariant.secondary,
                      label: 'Régénérer l’histoire (admin)',
                      icon: Icons.refresh_rounded,
                      onPressed: () => _runAdminStoryRegeneration(
                        context,
                        ref,
                        user,
                        child,
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const LunoraProgressBar(),
            error: (err, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Impossible de charger l’histoire.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.warmBeige,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.xs),
                Text(
                  '$err',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: LunoraSpacing.md),
                MagicalAppButton(
                  variant: MagicalButtonVariant.secondary,
                  label: 'Réessayer',
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.invalidate(todayStoryProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LunoraSpacing.sm + 2,
        vertical: LunoraSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: LunoraColors.nightBlue.withValues(alpha: 0.35),
        borderRadius: LunoraSpacing.radiusSm,
        border: Border.all(color: LunoraColors.mist.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: LunoraColors.starGoldSoft.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: LunoraColors.warmBeige.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: LunoraSpacing.sm),
      child: Material(
        color: LunoraColors.nightBlueLift.withValues(alpha: 0.55),
        borderRadius: LunoraSpacing.radiusMd,
        child: InkWell(
          borderRadius: LunoraSpacing.radiusMd,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: LunoraSpacing.md,
              vertical: LunoraSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(LunoraSpacing.sm),
                  decoration: BoxDecoration(
                    color: LunoraColors.violetSoft.withValues(alpha: 0.2),
                    borderRadius: LunoraSpacing.radiusSm,
                  ),
                  child: Icon(icon, color: LunoraColors.violetGlow, size: 22),
                ),
                const SizedBox(width: LunoraSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: LunoraColors.warmBeige,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: LunoraSpacing.xxs),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: LunoraColors.mist.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: LunoraColors.mist.withValues(alpha: 0.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
