import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';
import '../../../shared/widgets/magical/magical.dart';

/// Espace parent : stats simples + accès rapides (logique = navigation existante).
class ParentAreaScreen extends ConsumerWidget {
  const ParentAreaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authSessionProvider);
    final historyAsync = ref.watch(storyHistoryProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Espace parent',
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LunoraColors.nightSkyVertical),
          ),
          SafeArea(
            child: ListView(
              padding: LunoraSpacing.screen,
              children: [
                Text(
                  'Vue d’ensemble',
                  style: LunoraTextStyles.sectionTitle(theme.textTheme),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  user == null
                      ? 'Connecte-toi pour voir l’activité.'
                      : 'Compte : ${user.email}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.mist.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: LunoraSpacing.xl),
                historyAsync.when(
                  skipLoadingOnReload: true,
                  data: (stories) {
                    final total = stories.length;
                    final last = stories.isNotEmpty ? stories.first.title : '—';
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Histoires lues',
                            value: '$total',
                            hint: 'dans ton espace',
                          ),
                        ),
                        const SizedBox(width: LunoraSpacing.md),
                        Expanded(
                          child: _StatCard(
                            label: 'Dernière',
                            value: total > 0 ? '✓' : '—',
                            hint: total > 0 ? last : 'aucune pour l’instant',
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: LunoraProgressBar()),
                  ),
                  error: (e, _) => Text(
                    'Stats indisponibles.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
                const SizedBox(height: LunoraSpacing.xl),
                Text(
                  'Raccourcis',
                  style: LunoraTextStyles.sectionTitle(theme.textTheme),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                MagicalAppButton(
                  label: 'Historique des histoires',
                  icon: Icons.history_rounded,
                  variant: MagicalButtonVariant.secondary,
                  onPressed: () => context.push('/history'),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                MagicalAppButton(
                  label: 'Abonnement',
                  icon: Icons.workspace_premium_rounded,
                  variant: MagicalButtonVariant.secondary,
                  onPressed: () => context.push('/subscription'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(LunoraSpacing.md),
      decoration: BoxDecoration(
        borderRadius: LunoraSpacing.radiusMd,
        gradient: LunoraColors.cardAura,
        border: Border.all(color: LunoraColors.mist.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: LunoraColors.mist.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: LunoraSpacing.xs),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: LunoraColors.warmBeige,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: LunoraSpacing.xxs),
          Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: LunoraColors.mist.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}
