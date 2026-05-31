// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/colors.dart';
import '../../../core/validation/child_profile_rules.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/profile_story_preferences.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/elunai_fade_in.dart';
import '../../../shared/widgets/elunai_page_header.dart';
import '../../../shared/widgets/elunai_screen_shell.dart';
import '../../../shared/widgets/elunai_text_field.dart';
import '../../../shared/widgets/magical/magical.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';
import 'providers/child_profile_providers.dart';

enum _ProfileSaveChoice { nextSeries, restartSeries }

class ChildProfileSetupScreen extends ConsumerStatefulWidget {
  const ChildProfileSetupScreen({super.key});

  @override
  ConsumerState<ChildProfileSetupScreen> createState() =>
      _ChildProfileSetupScreenState();
}

class _ChildProfileSetupScreenState
    extends ConsumerState<ChildProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _extraStoryHints = TextEditingController();
  final _otherCharacter = TextEditingController();

  static const int kFixedStoryMinutes = 10;
  static const int kFixedSeriesDays = 7;
  static final List<StoryTone> kToneChoices = <StoryTone>[
    StoryTone.reassuring,
    StoryTone.playfulSoft,
    StoryTone.gentleAdventure,
    StoryTone.poetic,
  ];
  static const List<ProfileStoryUniverse> kUniverseChoices =
      ProfileStoryUniverse.values;
  static const List<String> kCharacterChoices = <String>[
    'L’enfant lui-même',
    'Un animal compagnon',
    'Un doudou magique',
    'Un ami imaginaire',
    'Un frère / une sœur',
    'Un petit héros inventé',
  ];

  int _birthMonth = 6;
  int _birthYear = 2019;
  StoryTone _tone = ChildProfileRules.defaultTone();
  final List<ProfileStoryUniverse> _universes = [
    ProfileStoryUniverse.gentleMagic,
  ];
  String _mainCharacter = kCharacterChoices.first;
  String _language = 'fr';

  /// Valeurs affichées = libellés stockés dans [ChildProfile.magicLevel] pour le LLM.
  String _storyStyle = 'Magique doux';

  static const List<String> kStoryStyleOptions = <String>[
    'Réaliste / quotidien',
    'Magique doux',
    'Aventure imaginaire',
  ];

  var _loading = false;
  var _currentStep = 0;

  static const int _lastStep = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final existing = ref.read(childProfileProvider);
      if (existing == null) return;
      setState(() {
        _firstName.text = existing.firstName;
        _birthMonth = existing.birthMonth;
        _birthYear = existing.birthYear;
        _tone = kToneChoices.contains(existing.preferredTone)
            ? existing.preferredTone
            : StoryTone.reassuring;
        _universes
          ..clear()
          ..addAll(
            existing.storyUniverses.isEmpty
                ? ProfileStoryUniverseMapper.parseStored(
                    const [],
                    legacyThemes: existing.preferredThemes,
                    legacyPrimaryUniverse: existing.storyUniverse,
                  )
                : existing.storyUniverses.take(
                    ProfileStoryUniverseMapper.maxSelections,
                  ),
          );
        _language = existing.language == 'en' ? 'en' : 'fr';
        _storyStyle = _coerceStoryStyle(existing.magicLevel);
        final characters = existing.personalityTraits;
        _mainCharacter = characters.firstWhere(
          kCharacterChoices.contains,
          orElse: () => kCharacterChoices.first,
        );
        _otherCharacter.text = characters
            .where((value) => !kCharacterChoices.contains(value))
            .join(', ');
        final hints = existing.extraStoryHints.trim();
        _extraStoryHints.text = hints.isNotEmpty
            ? hints
            : _composeLegacyHints(existing);
      });
    });
  }

  String _composeLegacyHints(ChildProfile c) {
    final parts = <String>[];
    if (c.preferredThemes.isNotEmpty) {
      parts.add('Préférences précédentes : ${c.preferredThemes.join(', ')}');
    }
    if (c.avoidThemes.isNotEmpty) {
      parts.add('À éviter : ${c.avoidThemes.join(', ')}');
    }
    final fears = c.softenedFears.isEmpty ? c.fearsToAddress : c.softenedFears;
    if (fears.isNotEmpty) {
      parts.add('Peurs / sujets sensibles : ${fears.join(', ')}');
    }
    final vals = c.valuesToTransmit.isEmpty
        ? c.valuesToTeach
        : c.valuesToTransmit;
    if (vals.isNotEmpty) {
      parts.add('Valeurs : ${vals.join(', ')}');
    }
    if (c.familiarElements.isNotEmpty) {
      parts.add('Éléments familiers : ${c.familiarElements.join(', ')}');
    }
    return parts.join('\n');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _extraStoryHints.dispose();
    _otherCharacter.dispose();
    super.dispose();
  }

  String _coerceOption(
    String? raw,
    List<String> options, {
    required String fallback,
  }) {
    final candidate = (raw ?? '').trim();
    if (candidate.isEmpty) return fallback;
    final normalizedCandidate = _normalizeKey(candidate);
    for (final option in options) {
      if (_normalizeKey(option) == normalizedCandidate) {
        return option;
      }
    }
    return fallback;
  }

  String _coerceStoryStyle(String? raw) {
    final normalized = _normalizeKey(raw ?? '');
    if (normalized.contains('realiste') || normalized.contains('quotidien')) {
      return 'Réaliste / quotidien';
    }
    if (normalized.contains('aventure')) return 'Aventure imaginaire';
    return _coerceOption(raw, kStoryStyleOptions, fallback: 'Magique doux');
  }

  String _normalizeKey(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('’', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _toggleUniverse(ProfileStoryUniverse universe) {
    setState(() {
      if (_universes.contains(universe)) {
        if (_universes.length > 1) _universes.remove(universe);
        return;
      }
      if (_universes.length < ProfileStoryUniverseMapper.maxSelections) {
        _universes.add(universe);
      }
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<_ProfileSaveChoice?> _askHowToSaveProfile() {
    return showDialog<_ProfileSaveChoice>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Comment appliquer ces réglages ?'),
        content: const Text(
          'La série en cours peut conserver ses réglages actuels. '
          'Recommencer une nouvelle série générera une nouvelle trame et un '
          'nouveau premier chapitre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(_ProfileSaveChoice.nextSeries),
            child: const Text('Enregistrer pour la prochaine série'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(_ProfileSaveChoice.restartSeries),
            child: const Text('Recommencer une nouvelle série'),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (_currentStep == 0 && !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_currentStep < _lastStep) {
      setState(() => _currentStep += 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    } else {
      context.safePopOrGo('/home');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final errMonth = ChildProfileRules.validateBirthMonth(_birthMonth);
    if (errMonth != null) {
      _showError(errMonth);
      return;
    }
    final errYear = ChildProfileRules.validateBirthYear(_birthYear);
    if (errYear != null) {
      _showError(errYear);
      return;
    }
    final errMinutes = ChildProfileRules.validateStoryMinutes(
      kFixedStoryMinutes,
    );
    if (errMinutes != null) {
      _showError(errMinutes);
      return;
    }
    final errSeries = ChildProfileRules.validateSeriesDaysForFormat(
      StoryFormat.serializedChapters,
      kFixedSeriesDays,
    );
    if (errSeries != null) {
      _showError(errSeries);
      return;
    }

    final user = ref.read(authSessionProvider);
    if (user == null) {
      if (mounted) context.go('/welcome');
      return;
    }

    try {
      final now = DateTime.now();
      final existing = ref.read(childProfileProvider);
      final id = existing?.id ?? const Uuid().v4();
      final ex = existing;
      final primaryUniverse = _universes.first;
      final otherCharacter = _otherCharacter.text.trim();

      final draft = ChildProfile(
        id: id,
        userId: user.id,
        firstName: _firstName.text.trim(),
        birthMonth: _birthMonth,
        birthYear: _birthYear,
        preferredThemes: _universes.map((e) => e.displayLabel).toList(),
        avoidThemes: ex?.avoidThemes ?? const [],
        personalityTraits: [
          _mainCharacter,
          if (otherCharacter.isNotEmpty) otherCharacter,
        ],
        fearsToAddress: ex?.fearsToAddress ?? const [],
        valuesToTeach: ex?.valuesToTeach ?? const [],
        language: _language,
        readingDurationMinutes: kFixedStoryMinutes,
        preferredUniverse: _universes.map((e) => e.displayLabel).join(', '),
        magicLevel: _storyStyle,
        adventureIntensity: ex?.adventureIntensity ?? 'équilibrée',
        softenedFears: ex?.softenedFears ?? const [],
        valuesToTransmit: ex?.valuesToTransmit ?? const [],
        bedtimeEnergyLevel: ex?.bedtimeEnergyLevel ?? 'calme',
        familiarElements: ex?.familiarElements ?? const [],
        tonightGoal: ex?.tonightGoal ?? 's’endormir calmement',
        extraStoryHints: _extraStoryHints.text.trim(),
        storyUniverse: primaryUniverse.primaryStoryUniverse,
        storyUniverses: List.unmodifiable(_universes),
        preferredTone: _tone,
        storyFormat: StoryFormat.serializedChapters,
        seriesDurationDays: kFixedSeriesDays,
        storyLengthMinutes: kFixedStoryMinutes,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final normalized = ChildProfileRules.normalize(draft);
      final businessErr = ChildProfileRules.validate(normalized);
      if (businessErr != null) {
        _showError(businessErr);
        return;
      }

      final choice = existing == null
          ? _ProfileSaveChoice.nextSeries
          : await _askHowToSaveProfile();
      if (choice == null || !mounted) return;

      setState(() => _loading = true);
      if (existing != null) {
        await ref
            .read(storyRepositoryProvider)
            .preserveActiveSeriesProfile(user: user, child: existing);
      }
      await ref.read(childProfileProvider.notifier).upsert(normalized);
      if (existing == null) {
        await ref
            .read(storyRepositoryProvider)
            .ensureTodayStory(user: user, child: normalized);
      }
      if (choice == _ProfileSaveChoice.restartSeries) {
        await ref
            .read(storyRepositoryProvider)
            .restartActiveSeries(user: user, child: normalized);
      }
      ref.invalidate(todayStoryProvider);
      ref.invalidate(storyHistoryProvider);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      _showError('Enregistrement impossible : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _universeTile(ProfileStoryUniverse universe) {
    return _ChoiceCard(
      label: universe.displayLabel,
      icon: _universeIcon(universe),
      selected: _universes.contains(universe),
      onTap: () => _toggleUniverse(universe),
    );
  }

  IconData _universeIcon(ProfileStoryUniverse universe) {
    return switch (universe) {
      ProfileStoryUniverse.animals => Icons.pets_rounded,
      ProfileStoryUniverse.gentleMagic => Icons.auto_awesome_rounded,
      ProfileStoryUniverse.adventure => Icons.explore_rounded,
      ProfileStoryUniverse.nature => Icons.park_rounded,
      ProfileStoryUniverse.everydayLife => Icons.home_rounded,
      ProfileStoryUniverse.emotionsConfidence => Icons.favorite_rounded,
      ProfileStoryUniverse.dinosaurs => Icons.landscape_rounded,
      ProfileStoryUniverse.space => Icons.nights_stay_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final existingProfile = ref.watch(childProfileProvider);
    final years = List<int>.generate(18, (i) => DateTime.now().year - i);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ElunaiAppBar(title: 'Profil enfant'),
      body: ElunaiScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: ElunaiFadeIn(
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: AppSizes.screenPadding,
                children: [
                  if (existingProfile != null) ...[
                    ChildProfileCard(
                      firstName: existingProfile.firstName,
                      caption: 'Ajuste les préférences quand tu veux',
                    ),
                    const SizedBox(height: AppSizes.lg),
                  ],
                  const ElunaiPageHeader(
                    compact: true,
                    icon: Icons.child_care_rounded,
                    title: 'Créer le profil narratif',
                    subtitle:
                        'Quelques repères doux suffisent pour personnaliser le rituel du soir.',
                    badge: '4 étapes · modifiable à tout moment',
                  ),
                  const SizedBox(height: AppSizes.lg),
                  _ProfileFlowHeader(currentStep: _currentStep),
                  const SizedBox(height: AppSizes.md),
                  if (_currentStep == 0)
                    _SectionCard(
                      title: 'Profil enfant',
                      subtitle: 'Obligatoire : prénom + âge.',
                      child: Column(
                        children: [
                          ElunaiTextField(
                            controller: _firstName,
                            label: 'Prénom',
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              final v = value?.trim() ?? '';
                              if (v.isEmpty) return 'Prénom obligatoire';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSizes.md),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _birthMonth,
                                  decoration: const InputDecoration(
                                    labelText: 'Mois',
                                  ),
                                  items: List.generate(
                                    12,
                                    (i) => DropdownMenuItem(
                                      value: i + 1,
                                      child: Text('${i + 1}'),
                                    ),
                                  ),
                                  onChanged: (v) => setState(
                                    () => _birthMonth = v ?? _birthMonth,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _birthYear,
                                  decoration: const InputDecoration(
                                    labelText: 'Année',
                                  ),
                                  items: years
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text('$y'),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(
                                    () => _birthYear = v ?? _birthYear,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _language,
                            decoration: const InputDecoration(
                              labelText: 'Langue de l’histoire',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'fr',
                                child: Text('Français'),
                              ),
                              DropdownMenuItem(
                                value: 'en',
                                child: Text('Anglais'),
                              ),
                            ],
                            onChanged: (v) =>
                                setState(() => _language = v ?? _language),
                          ),
                          const SizedBox(height: AppSizes.md),
                          ElunaiTextField(
                            controller: _extraStoryHints,
                            label: 'Ce que l’histoire doit prendre en compte',
                            hint:
                                'Exemples : aime les dinosaures, peur du noir, adore son doudou, préfère les histoires calmes…',
                            maxLines: 5,
                            minLines: 3,
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Tu peux écrire librement. Elunai utilisera ces détails pour personnaliser les histoires.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ElunaiColors.storybookInkMuted,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                  if (_currentStep == 1) ...[
                    _SectionCard(
                      title: 'Préférences d’histoire',
                      subtitle:
                          'Choisis jusqu’à 3 univers. Tu pourras modifier plus tard.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_universes.length}/3 univers sélectionnés',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ElunaiColors.storybookInkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: AppSizes.sm,
                            mainAxisSpacing: AppSizes.sm,
                            childAspectRatio: 1.72,
                            children: kUniverseChoices
                                .map(_universeTile)
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_currentStep == 2) ...[
                    _SectionCard(
                      title: 'Personnage principal',
                      subtitle:
                          'Choisis le héros qui accompagnera les histoires.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final character in kCharacterChoices) ...[
                            _ChoiceCard(
                              label: character,
                              icon: Icons.face_retouching_natural_rounded,
                              selected: _mainCharacter == character,
                              onTap: () =>
                                  setState(() => _mainCharacter = character),
                            ),
                            const SizedBox(height: AppSizes.sm),
                          ],
                          ElunaiTextField(
                            controller: _otherCharacter,
                            label: 'Autre personnage',
                            hint:
                                'Exemple : un renard gentil, une licorne calme, un robot protecteur…',
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_currentStep == 3) ...[
                    _SectionCard(
                      title: 'Ambiance du soir',
                      subtitle:
                          'Une ambiance rassurante reste sélectionnée par défaut.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: AppSizes.sm,
                            mainAxisSpacing: AppSizes.sm,
                            childAspectRatio: 1.9,
                            children: [
                              for (final tone in kToneChoices)
                                _ChoiceCard(
                                  label: tone.displayLabel,
                                  icon: Icons.nights_stay_rounded,
                                  selected: _tone == tone,
                                  onTap: () => setState(() => _tone = tone),
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _storyStyle,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Style d’histoire',
                            ),
                            items: kStoryStyleOptions
                                .map(
                                  (style) => DropdownMenuItem(
                                    value: style,
                                    child: Text(style),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _storyStyle = value ?? _storyStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSizes.lg),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.md),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _previousStep,
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: Text(
                              _currentStep == 0 ? 'Retour' : 'Précédent',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: MagicalAppButton(
                            label: _currentStep == _lastStep
                                ? 'Enregistrer'
                                : 'Continuer',
                            icon: _currentStep == _lastStep
                                ? Icons.save_rounded
                                : Icons.arrow_forward_rounded,
                            onPressed: _currentStep == _lastStep
                                ? _submit
                                : _nextStep,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSizes.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFlowHeader extends StatelessWidget {
  const _ProfileFlowHeader({required this.currentStep});

  final int currentStep;

  static const _labels = ['Profil', 'Univers', 'Héros', 'Ambiance'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < _labels.length; i++) ...[
              Expanded(
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: i <= currentStep
                            ? ElunaiColors.forestGreen
                            : ElunaiColors.storybookInkMuted.withValues(
                                alpha: 0.18,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      _labels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: i == currentStep
                            ? ElunaiColors.forestGreen
                            : ElunaiColors.storybookInkMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != _labels.length - 1) const SizedBox(width: AppSizes.xs),
            ],
          ],
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Étape ${currentStep + 1}/${_labels.length}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: ElunaiColors.storybookInkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: light
            ? ElunaiColors.storybookSurface
            : ElunaiColors.nightBlueLift.withValues(alpha: 0.55),
        border: Border.all(
          color: light
              ? ElunaiColors.storybookInkMuted.withValues(alpha: 0.12)
              : ElunaiColors.mist.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: light ? ElunaiColors.storybookInk : ElunaiColors.warmBeige,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: light
                  ? ElunaiColors.storybookInkMuted
                  : ElunaiColors.mist.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? ElunaiColors.forestGreen.withValues(alpha: 0.09)
          : ElunaiColors.storybookSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? ElunaiColors.forestGreen
              : ElunaiColors.storybookInkMuted.withValues(alpha: 0.18),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.sm),
          child: Row(
            children: [
              Icon(icon, size: 21, color: ElunaiColors.forestGreen),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: ElunaiColors.storybookInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: ElunaiColors.forestGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
