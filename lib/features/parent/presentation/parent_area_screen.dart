import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/enums/universe_type.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';
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
      body: LunoraScreenShell(
        showStarfield: true,
        starCount: 34,
        child: SafeArea(
          child: ListView(
            padding: LunoraSpacing.screen,
            children: [
              LunoraFadeIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
  var storyMinutes = existing?.storyLengthMinutes ?? 10;
  var format = existing?.storyFormat ?? StoryFormat.dailyStandalone;
  var seriesDays = (existing?.seriesDurationDays ?? 0) == 0
      ? 7
      : existing!.seriesDurationDays;

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
                    DropdownButtonFormField<int>(
                      initialValue: storyMinutes,
                      decoration: const InputDecoration(labelText: 'Durée'),
                      items: const [
                        DropdownMenuItem(value: 5, child: Text('5 min')),
                        DropdownMenuItem(value: 10, child: Text('10 min')),
                        DropdownMenuItem(value: 15, child: Text('15 min')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => storyMinutes = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<StoryFormat>(
                      initialValue: format,
                      decoration: const InputDecoration(
                        labelText: 'Format narratif',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: StoryFormat.dailyStandalone,
                          child: Text('Histoire du jour'),
                        ),
                        DropdownMenuItem(
                          value: StoryFormat.serializedChapters,
                          child: Text('Série en chapitres'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => format = value);
                      },
                    ),
                    if (format == StoryFormat.serializedChapters) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        initialValue: seriesDays,
                        decoration: const InputDecoration(
                          labelText: 'Durée de série',
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 jours')),
                          DropdownMenuItem(value: 14, child: Text('14 jours')),
                          DropdownMenuItem(value: 21, child: Text('21 jours')),
                          DropdownMenuItem(value: 28, child: Text('28 jours')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => seriesDays = value);
                        },
                      ),
                    ],
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
    universeType: existing?.universeType ?? UniverseType.skyAndStars,
    preferredTone: existing?.preferredTone ?? StoryTone.reassuring,
    storyFormat: format,
    seriesDurationDays: format == StoryFormat.serializedChapters ? seriesDays : 0,
    storyLengthMinutes: storyMinutes,
    createdAt: existing?.createdAt ?? DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await ref.read(childProfileProvider.notifier).upsert(profile);
  await ref
      .read(storyRepositoryProvider)
      .adminRegenerateTodayStory(user: user, child: profile);
  ref.invalidate(todayStoryProvider);
  ref.invalidate(storyHistoryProvider);
  if (context.mounted) {
    context.push('/story');
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
