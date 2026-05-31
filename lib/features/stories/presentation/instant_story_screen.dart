import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/di/providers.dart';
import '../../../services/story_generation/story_adaptation_engine.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/elunai_fade_in.dart';
import '../../../shared/widgets/elunai_glass_card.dart';
import '../../../shared/widgets/elunai_night_scaffold.dart';
import '../../../shared/widgets/elunai_primary_button.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'providers/story_providers.dart';

class InstantStoryScreen extends ConsumerStatefulWidget {
  const InstantStoryScreen({super.key});

  @override
  ConsumerState<InstantStoryScreen> createState() => _InstantStoryScreenState();
}

class _InstantStoryScreenState extends ConsumerState<InstantStoryScreen> {
  static const StoryAdaptationEngine _adaptationEngine =
      StoryAdaptationEngine();
  var _loading = false;

  Future<void> _generate() async {
    final user = ref.read(authSessionProvider);
    final child = ref.read(childProfileProvider);
    if (user == null || child == null) return;
    setState(() => _loading = true);
    try {
      final story = await ref
          .read(storyRepositoryProvider)
          .ensureTodayStory(user: user, child: child);
      ref.invalidate(todayStoryProvider);
      ref.invalidate(storyHistoryProvider);
      if (mounted) {
        context.go('/story?id=${Uri.encodeComponent(story.id)}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Generation impossible : $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(childProfileProvider);
    if (child == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/setup-child');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final adaptation = _adaptationEngine.fromChildProfile(child);
    final childName = child.firstName.trim().isEmpty
        ? 'ton enfant'
        : child.firstName.trim();

    return ElunaiNightScaffold(
      scrollable: true,
      appBar: ElunaiAppBar(title: '✨ Génération'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ElunaiFadeIn(
            child: ElunaiGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prêt pour $childName',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: ElunaiColors.warmBeige,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: ElunaiSpacing.sm),
                  Text(
                    'Elunai adapte automatiquement le vocabulaire, la longueur et le rythme selon ${adaptation.ageYears} ans.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ElunaiColors.mist.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: ElunaiSpacing.lg),
                  ElunaiPrimaryButton(
                    label: 'Générer maintenant',
                    icon: Icons.auto_stories_rounded,
                    onPressed: _loading ? null : _generate,
                  ),
                  const SizedBox(height: ElunaiSpacing.sm),
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
