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
                  'Elunai Histoires Intelligentes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: LunoraColors.warmBeige,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                ),
                const SizedBox(height: LunoraSpacing.xs),
                Text(
                  'Pour $childName',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: LunoraColors.mist,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Une seule action. Elunai adapte automatiquement l’histoire à son âge.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.82),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LunoraSpacing.lg),
          LunoraFadeIn(
            delay: const Duration(milliseconds: 120),
            child: _StoryHubCard(
              user: user,
              childProfile: child,
              asyncStory: todayStoryAsync,
              onRead: (story) => context.push(
                '/story?id=${Uri.encodeComponent(story.id)}',
              ),
              onGenerate: () => context.push('/generate'),
              onAdminRegenerate: () => _runAdminStoryRegeneration(
                context,
                ref,
                user,
                child,
              ),
            ),
          ),
          const SizedBox(height: LunoraSpacing.xl),
          Row(
            children: [
              _InlineAction(
                icon: Icons.child_care_rounded,
                label: 'Profil',
                onTap: () => context.push('/setup-child'),
              ),
              const SizedBox(width: LunoraSpacing.sm),
              _InlineAction(
                icon: Icons.history_rounded,
                label: 'Historique',
                onTap: () => context.push('/history'),
              ),
            ],
          ),
          const SizedBox(height: LunoraSpacing.xl),
        ],
      ),
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
          height: 150,
          child: Center(child: LunoraProgressBar()),
        ),
        error: (err, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LunoraSectionTitle('Histoire'),
            const SizedBox(height: LunoraSpacing.sm),
            Text(
              'Impossible de préparer une histoire pour le moment.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.warmBeige,
                  ),
            ),
            const SizedBox(height: LunoraSpacing.md),
            LunoraPrimaryButton(
              label: 'Nouvelle histoire',
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
                const LunoraSectionTitle('Histoire'),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  'Aucune histoire prête pour le moment.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.86),
                      ),
                ),
                const SizedBox(height: LunoraSpacing.md),
                LunoraPrimaryButton(
                  label: 'Nouvelle histoire',
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
                'Prête pour $childName. Un tap pour commencer.',
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
                label: 'Continuer l’histoire',
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

class _InlineAction extends StatelessWidget {
  const _InlineAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: LunoraColors.nightBlueLift.withValues(alpha: 0.48),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: LunoraSpacing.md,
            vertical: LunoraSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: LunoraColors.starGoldSoft),
              const SizedBox(width: LunoraSpacing.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: LunoraColors.warmBeige,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
