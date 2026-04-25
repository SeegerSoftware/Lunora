import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../services/story_generation/story_adaptation_engine.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_glass_card.dart';
import '../../../shared/widgets/lunora_night_scaffold.dart';
import '../../../shared/widgets/lunora_primary_button.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import 'providers/story_providers.dart';

class InstantStoryScreen extends ConsumerWidget {
  const InstantStoryScreen({super.key});

  static const StoryAdaptationEngine _adaptationEngine = StoryAdaptationEngine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(childProfileProvider);
    if (child == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/setup-child');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final adaptation = _adaptationEngine.fromChildProfile(child);
    final childName = child.firstName.trim().isEmpty ? 'ton enfant' : child.firstName.trim();

    return LunoraNightScaffold(
      scrollable: true,
      starCount: 24,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Génération instantanée',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: LunoraFadeIn(
            child: LunoraGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prêt pour $childName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: LunoraColors.warmBeige,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: LunoraSpacing.sm),
                  Text(
                    'Elunai adapte automatiquement le vocabulaire, la longueur et le rythme selon ${adaptation.ageYears} ans.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: LunoraColors.mist.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: LunoraSpacing.lg),
                  LunoraPrimaryButton(
                    label: 'Générer maintenant',
                    icon: Icons.auto_stories_rounded,
                    onPressed: () {
                      ref.invalidate(todayStoryProvider);
                      context.go('/story');
                    },
                  ),
                  const SizedBox(height: LunoraSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => context.push('/setup-child'),
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Options avancées du profil'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
