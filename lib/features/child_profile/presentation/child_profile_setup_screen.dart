// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/validation/child_profile_rules.dart';
import '../../../routing/safe_navigation.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/story_universe.dart';
import '../../../shared/widgets/elunai_layout.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
import '../../../shared/widgets/lunora_page_header.dart';
import '../../../shared/widgets/lunora_screen_shell.dart';
import '../../../shared/widgets/lunora_text_field.dart';
import '../../../shared/widgets/magical/magical.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../stories/presentation/providers/story_providers.dart';
import 'providers/child_profile_providers.dart';

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
  final _preferredThemes = TextEditingController();
  final _personalityTraits = TextEditingController();
  final _extraStoryHints = TextEditingController();

  static const int kFixedStoryMinutes = 10;
  static const int kFixedSeriesDays = 7;
  static final List<StoryUniverse> kUniverseChoices = List<StoryUniverse>.from(
    StoryUniverse.values,
  );
  static final List<StoryTone> kToneChoices = <StoryTone>[
    StoryTone.reassuring,
    StoryTone.gentleAdventure,
    StoryTone.poetic,
  ];

  int _birthMonth = 6;
  int _birthYear = 2019;
  StoryTone _tone = ChildProfileRules.defaultTone();
  StoryUniverse _universe = ChildProfileRules.defaultStoryUniverse();
  String _language = 'fr';

  /// Valeurs affichées = libellés stockés dans [ChildProfile.magicLevel] pour le LLM.
  String _storyStyle = 'fantastique doux';

  static const List<String> kStoryStyleOptions = <String>[
    'fantastique doux',
    'réaliste / quotidien',
    'mélange doux (magie + réel)',
    'poétique / onirique',
  ];

  static const List<String> kThemeSuggestionChips = <String>[
    'animaux',
    'nature',
    'espace',
    'mer',
    'forêt',
    'musique',
    'amitié',
    'famille',
    'école',
    'sport',
    'voyage',
    'dinosaures',
    'conte de fées',
    'super-héros',
    'véhicules',
    'cuisine',
    'jardin',
    'montagne',
    'hiver',
    'printemps',
    'robots gentils',
    'fées bienveillantes',
  ];

  static const List<String> kCharacterSuggestionChips = <String>[
    'enfant curieux',
    'fille courageuse',
    'garçon timide',
    'animal parlant',
    'doudou magique',
    'fée bienveillante',
    'robot gentil',
    'jumelles complices',
    'grand frère',
    'petite sœur',
    'chat espiègle',
    'chien fidèle',
    'oiseau messager',
    'dragon doux',
    'lutin rigolo',
    'licorne calme',
    'sorcière bienveillante',
  ];

  var _loading = false;
  var _currentStep = 0;

  static const int _lastStep = 2;

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
        _universe = kUniverseChoices.contains(existing.storyUniverse)
            ? existing.storyUniverse
            : ChildProfileRules.defaultStoryUniverse();
        _language = existing.language == 'en' ? 'en' : 'fr';
        _storyStyle = _coerceOption(
          existing.magicLevel,
          kStoryStyleOptions,
          fallback: 'fantastique doux',
        );
        _preferredThemes.text = existing.preferredThemes.join(', ');
        _personalityTraits.text = existing.personalityTraits.join(', ');
        final hints = existing.extraStoryHints.trim();
        _extraStoryHints.text = hints.isNotEmpty
            ? hints
            : _composeLegacyHints(existing);
      });
    });
  }

  String _composeLegacyHints(ChildProfile c) {
    final parts = <String>[];
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
    _preferredThemes.dispose();
    _personalityTraits.dispose();
    _extraStoryHints.dispose();
    super.dispose();
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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

  void _appendChipValue(TextEditingController controller, String value) {
    final current = _splitList(controller.text);
    final normalized = current.map(_normalizeKey).toSet();
    if (normalized.contains(_normalizeKey(value))) return;
    final updated = [...current, value];
    setState(() => controller.text = updated.join(', '));
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

    setState(() => _loading = true);
    try {
      final now = DateTime.now();
      final existing = ref.read(childProfileProvider);
      final id = existing?.id ?? const Uuid().v4();
      final ex = existing;

      final draft = ChildProfile(
        id: id,
        userId: user.id,
        firstName: _firstName.text.trim(),
        birthMonth: _birthMonth,
        birthYear: _birthYear,
        preferredThemes: _splitList(_preferredThemes.text),
        avoidThemes: ex?.avoidThemes ?? const [],
        personalityTraits: _splitList(_personalityTraits.text),
        fearsToAddress: ex?.fearsToAddress ?? const [],
        valuesToTeach: ex?.valuesToTeach ?? const [],
        language: _language,
        readingDurationMinutes: kFixedStoryMinutes,
        preferredUniverse: '${_universe.emoji} ${_universe.displayName}',
        magicLevel: _storyStyle,
        adventureIntensity: ex?.adventureIntensity ?? 'équilibrée',
        softenedFears: ex?.softenedFears ?? const [],
        valuesToTransmit: ex?.valuesToTransmit ?? const [],
        bedtimeEnergyLevel: ex?.bedtimeEnergyLevel ?? 'calme',
        familiarElements: ex?.familiarElements ?? const [],
        tonightGoal: ex?.tonightGoal ?? 's’endormir calmement',
        extraStoryHints: _extraStoryHints.text.trim(),
        storyUniverse: _universe,
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

      await ref.read(childProfileProvider.notifier).upsert(normalized);
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

  Widget _universeTile(StoryUniverse u) {
    final theme = Theme.of(context);
    final m = u.meta;
    final selected = u == _universe;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Material(
        color: selected
            ? LunoraColors.forestGreen.withValues(alpha: 0.08)
            : LunoraColors.storybookSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? LunoraColors.forestGreen
                : LunoraColors.storybookInkMuted.withValues(alpha: 0.18),
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _universe = u),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Text(m.emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    m.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: LunoraColors.storybookInk,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: LunoraColors.forestGreen,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existingProfile = ref.watch(childProfileProvider);
    final years = List<int>.generate(18, (i) => DateTime.now().year - i);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const ElunaiAppBar(title: 'Profil enfant'),
      body: LunoraScreenShell(
        showStarfield: true,
        child: SafeArea(
          child: LunoraFadeIn(
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
                  const LunoraPageHeader(
                    compact: true,
                    icon: Icons.child_care_rounded,
                    title: 'Créer le profil narratif',
                    subtitle:
                        'Quelques choix suffisent pour guider le ton, les thèmes et la durée des histoires.',
                    badge: '3 étapes · modifiable à tout moment',
                  ),
                  const SizedBox(height: AppSizes.lg),
                  const _StoryDefaultsCard(),
                  const SizedBox(height: AppSizes.lg),
                  _ProfileFlowHeader(currentStep: _currentStep),
                  const SizedBox(height: AppSizes.md),
                  if (_currentStep == 0)
                    _SectionCard(
                      title: 'Profil enfant',
                      subtitle: 'Obligatoire : prénom + âge.',
                      child: Column(
                        children: [
                          LunoraTextField(
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
                        ],
                      ),
                    ),
                  if (_currentStep == 1) ...[
                    _SectionCard(
                      title: 'Guide pour les histoires',
                      subtitle:
                          'Touche une idée pour l’ajouter, ou écris librement (virgules ou lignes).',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LunoraTextField(
                            controller: _preferredThemes,
                            label: 'Thème principal',
                            hint: 'ex. animaux de la forêt, océan calme…',
                          ),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: kThemeSuggestionChips,
                            onSelected: (value) =>
                                _appendChipValue(_preferredThemes, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          LunoraTextField(
                            controller: _personalityTraits,
                            label: 'Personnage principal',
                            hint: 'ex. un chat curieux, ta fille courageuse…',
                          ),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: kCharacterSuggestionChips,
                            onSelected: (value) =>
                                _appendChipValue(_personalityTraits, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _storyStyle,
                            decoration: const InputDecoration(
                              labelText: 'Style d’histoire',
                            ),
                            items: kStoryStyleOptions
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _storyStyle = v ?? _storyStyle),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'Univers du soir',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: LunoraColors.storybookInk,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Une ambiance par soir — Elunai s’en inspire pour les détails (modifiable plus tard).',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: LunoraColors.storybookInkMuted,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          ...kUniverseChoices.map(_universeTile),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<StoryTone>(
                            value: _tone,
                            decoration: const InputDecoration(labelText: 'Ton'),
                            isExpanded: true,
                            items: kToneChoices
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.displayLabel),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _tone = v ?? _tone),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_currentStep == 2) ...[
                    _SectionCard(
                      title: 'Résumé avant sauvegarde',
                      subtitle:
                          'Vérifie les repères principaux. Les détails restent modifiables plus tard.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProfileSummaryRow(
                            icon: Icons.person_rounded,
                            label: 'Enfant',
                            value: _firstName.text.trim().isEmpty
                                ? 'Prénom à compléter'
                                : _firstName.text.trim(),
                          ),
                          _ProfileSummaryRow(
                            icon: Icons.palette_rounded,
                            label: 'Style',
                            value: _storyStyle,
                          ),
                          _ProfileSummaryRow(
                            icon: Icons.explore_rounded,
                            label: 'Univers',
                            value: _universe.displayName,
                          ),
                          _ProfileSummaryRow(
                            icon: Icons.record_voice_over_rounded,
                            label: 'Ton',
                            value: _tone.displayLabel,
                          ),
                          const SizedBox(height: AppSizes.md),
                          LunoraTextField(
                            controller: _extraStoryHints,
                            label: 'Notes libres pour Elunai',
                            hint:
                                'Ex. éviter les loups, valoriser le partage, inclure le doudou préféré…',
                            maxLines: 5,
                            minLines: 3,
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

  static const _labels = ['Profil', 'Histoire', 'Notes'];

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
                            ? LunoraColors.forestGreen
                            : LunoraColors.storybookInkMuted.withValues(
                                alpha: 0.18,
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      _labels[i],
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: i == currentStep
                            ? LunoraColors.forestGreen
                            : LunoraColors.storybookInkMuted,
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
            color: LunoraColors.storybookInkMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StoryDefaultsCard extends StatelessWidget {
  const _StoryDefaultsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: LunoraColors.honeyYellow.withValues(alpha: 0.18),
        border: Border.all(
          color: LunoraColors.honeyYellowDeep.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            color: LunoraColors.forestGreen,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              'Format par défaut : série en 7 chapitres, un chapitre par soir, lecture environ 10 minutes.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: LunoraColors.storybookInk,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
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
            ? LunoraColors.storybookSurface
            : LunoraColors.nightBlueLift.withValues(alpha: 0.55),
        border: Border.all(
          color: light
              ? LunoraColors.storybookInkMuted.withValues(alpha: 0.12)
              : LunoraColors.mist.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: light ? LunoraColors.storybookInk : LunoraColors.warmBeige,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: light
                  ? LunoraColors.storybookInkMuted
                  : LunoraColors.mist.withValues(alpha: 0.78),
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

class _ProfileSummaryRow extends StatelessWidget {
  const _ProfileSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: LunoraColors.forestGreen),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: LunoraColors.storybookInkMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: LunoraColors.storybookInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipSuggestions extends StatelessWidget {
  const _ChipSuggestions({required this.options, required this.onSelected});

  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.xs,
      children: [
        for (final option in options)
          ActionChip(
            label: Text(option),
            onPressed: () => onSelected(option),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(
                color: light
                    ? LunoraColors.forestGreen.withValues(alpha: 0.22)
                    : LunoraColors.mist.withValues(alpha: 0.2),
              ),
            ),
            backgroundColor: light
                ? LunoraColors.storybookCreamDeep
                : LunoraColors.nightBlue.withValues(alpha: 0.45),
            labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: light ? LunoraColors.storybookInk : LunoraColors.warmBeige,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
