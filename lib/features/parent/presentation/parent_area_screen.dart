import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/colors.dart';
import '../../../core/validation/child_profile_rules.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/story_universe.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
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
      appBar: ElunaiAppBar(
        title: 'Espace parent',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: ListView(
            padding: LunoraSpacing.screen,
            children: [
              LunoraFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Text(
                  'Espace parent',
                  style: LunoraTextStyles.sectionTitle(theme.textTheme),
                ),
                const SizedBox(height: LunoraSpacing.sm),
                Text(
                  user == null
                      ? 'Connecte-toi pour voir l’activité.'
                      : '👋 ${user.email}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: LunoraColors.storybookInk.withValues(alpha: 0.78),
                    height: 1.4,
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
                  label: 'Générer une histoire (test)',
                  icon: Icons.auto_stories_rounded,
                  onPressed: user == null
                      ? null
                      : () => _openQuickStoryGenerator(
                          context: context,
                          ref: ref,
                          user: user,
                        ),
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
        ),
      ),
    );
  }
}

Future<void> _openQuickStoryGenerator({
  required BuildContext context,
  required WidgetRef ref,
  required UserModel user,
}) async {
  final formKey = GlobalKey<FormState>();
  final existing = ref.read(childProfileProvider);
  final firstNameCtrl = TextEditingController(text: existing?.firstName ?? '');
  final themesCtrl = TextEditingController(
    text: existing?.preferredThemes.join(', ') ?? '',
  );
  var birthYear = existing?.birthYear ?? 2019;

  final created = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Générer une histoire'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: firstNameCtrl,
                      decoration: const InputDecoration(labelText: 'Prénom'),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Prénom obligatoire';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: themesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Thèmes préférés (optionnel)',
                        hintText: 'étoiles, dragons gentils, forêt',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: birthYear,
                      decoration: const InputDecoration(labelText: 'Année'),
                      items: List<int>.generate(
                        16,
                        (i) => DateTime.now().year - i,
                      ).map((year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text('$year'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => birthYear = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Série en 7 chapitres · lecture ~10 min (réglage unique pour l’instant).',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Créer et générer'),
              ),
            ],
          );
        },
      );
    },
  );

  if (created != true) return;

  final profile = ChildProfile(
    id: existing?.id ?? const Uuid().v4(),
    userId: user.id,
    firstName: firstNameCtrl.text.trim(),
    birthMonth: existing?.birthMonth ?? 6,
    birthYear: birthYear,
    preferredThemes: themesCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(),
    avoidThemes: existing?.avoidThemes ?? const [],
    personalityTraits: existing?.personalityTraits ?? const [],
    fearsToAddress: existing?.fearsToAddress ?? const [],
    valuesToTeach: existing?.valuesToTeach ?? const [],
    storyUniverse: existing?.storyUniverse ?? StoryUniverse.magicAndFairy,
    preferredTone: existing?.preferredTone ?? StoryTone.reassuring,
    storyFormat: StoryFormat.serializedChapters,
    seriesDurationDays: 7,
    storyLengthMinutes: 10,
    readingDurationMinutes: 10,
    extraStoryHints: existing?.extraStoryHints ?? '',
    createdAt: existing?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );

  try {
    final normalized = ChildProfileRules.normalize(profile);
    await ref.read(childProfileProvider.notifier).upsert(normalized);
    await ref
        .read(storyRepositoryProvider)
        .adminRegenerateTodayStory(user: user, child: normalized);
    ref.invalidate(todayStoryProvider);
    ref.invalidate(storyHistoryProvider);
    if (context.mounted) {
      context.push('/story');
    }
  } catch (e) {
    if (!context.mounted) return;
    final msg = e is Exception ? e.toString().replaceFirst('Exception: ', '') : '$e';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
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
