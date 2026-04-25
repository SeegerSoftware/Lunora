// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/validation/child_profile_rules.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/enums/universe_type.dart';
import '../../../shared/widgets/lunora_fade_in.dart';
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
  final _avoidThemes = TextEditingController();
  final _personalityTraits = TextEditingController();
  final _fears = TextEditingController();
  final _values = TextEditingController();
  final _familiarElements = TextEditingController();

  int _birthMonth = 6;
  int _birthYear = 2019;
  int _storyMinutes = 10;
  String _storyType = 'soir';
  StoryFormat _format = StoryFormat.dailyStandalone;
  int _seriesDays = 7;
  StoryTone _tone = ChildProfileRules.defaultTone();
  UniverseType _universe = ChildProfileRules.defaultUniverseType();
  String _language = 'fr';
  String _magicLevel = 'légèrement magique';
  String _adventureIntensity = 'équilibrée';
  String _bedtimeEnergyLevel = 'calme';
  String _tonightGoal = 's’endormir calmement';

  static const List<String> _magicLevelOptions = <String>[
    'réaliste',
    'légèrement magique',
    'très magique',
  ];
  static const List<String> _adventureOptions = <String>[
    'très douce',
    'équilibrée',
    'aventureuse mais rassurante',
  ];
  static const List<String> _bedtimeOptions = <String>[
    'très calme',
    'calme',
    'un peu dynamique',
    'a besoin d’être apaisé',
  ];
  static const List<String> _tonightGoalOptions = <String>[
    's’endormir calmement',
    'se rassurer',
    'rire un peu',
    'apprendre quelque chose',
    'prolonger une série',
  ];

  var _loading = false;
  var _showAdvanced = false;

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
        _storyMinutes = existing.storyLengthMinutes;
        _format = existing.storyFormat;
        _seriesDays = existing.seriesDurationDays == 0
            ? 7
            : existing.seriesDurationDays;
        _tone = existing.preferredTone;
        _storyType = _storyTypeFromTone(existing.preferredTone);
        _universe = existing.universeType;
        _language = existing.language == 'en' ? 'en' : 'fr';
        _magicLevel = _coerceOption(
          existing.magicLevel,
          _magicLevelOptions,
          fallback: 'légèrement magique',
        );
        _adventureIntensity = _coerceOption(
          existing.adventureIntensity,
          _adventureOptions,
          fallback: 'équilibrée',
        );
        _bedtimeEnergyLevel = _coerceOption(
          existing.bedtimeEnergyLevel,
          _bedtimeOptions,
          fallback: 'calme',
        );
        _tonightGoal = _coerceOption(
          existing.tonightGoal,
          _tonightGoalOptions,
          fallback: 's’endormir calmement',
        );
        _preferredThemes.text = existing.preferredThemes.join(', ');
        _avoidThemes.text = existing.avoidThemes.join(', ');
        _personalityTraits.text = existing.personalityTraits.join(', ');
        _fears.text = existing.softenedFears.join(', ');
        _values.text = existing.valuesToTransmit.join(', ');
        _familiarElements.text = existing.familiarElements.join(', ');
      });
    });
  }

  @override
  void dispose() {
    _firstName.dispose();
    _preferredThemes.dispose();
    _avoidThemes.dispose();
    _personalityTraits.dispose();
    _fears.dispose();
    _values.dispose();
    _familiarElements.dispose();
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

  StoryTone _toneFromStoryType(String type) {
    switch (type) {
      case 'aventure':
        return StoryTone.gentleAdventure;
      case 'educatif':
        return StoryTone.poetic;
      case 'soir':
      default:
        return StoryTone.reassuring;
    }
  }

  String _storyTypeFromTone(StoryTone tone) {
    switch (tone) {
      case StoryTone.gentleAdventure:
        return 'aventure';
      case StoryTone.poetic:
        return 'educatif';
      case StoryTone.playfulSoft:
      case StoryTone.reassuring:
        return 'soir';
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
    final errMinutes = ChildProfileRules.validateStoryMinutes(_storyMinutes);
    if (errMinutes != null) {
      _showError(errMinutes);
      return;
    }
    final errSeries = ChildProfileRules.validateSeriesDaysForFormat(
      _format,
      _seriesDays,
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

      final draft = ChildProfile(
        id: id,
        userId: user.id,
        firstName: _firstName.text.trim(),
        birthMonth: _birthMonth,
        birthYear: _birthYear,
        preferredThemes: _splitList(_preferredThemes.text),
        avoidThemes: _splitList(_avoidThemes.text),
        personalityTraits: _splitList(_personalityTraits.text),
        fearsToAddress: _splitList(_fears.text),
        valuesToTeach: _splitList(_values.text),
        language: _language,
        readingDurationMinutes: _storyMinutes,
        preferredUniverse: _universe.displayLabel,
        magicLevel: _magicLevel,
        adventureIntensity: _adventureIntensity,
        softenedFears: _splitList(_fears.text),
        valuesToTransmit: _splitList(_values.text),
        bedtimeEnergyLevel: _bedtimeEnergyLevel,
        familiarElements: _splitList(_familiarElements.text),
        tonightGoal: _tonightGoal,
        universeType: _universe,
        preferredTone: _tone,
        storyFormat: _format,
        seriesDurationDays: _format == StoryFormat.serializedChapters
            ? _seriesDays
            : 0,
        storyLengthMinutes: _storyMinutes,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );

      final normalized = ChildProfileRules.normalize(draft);
      final normalizedWithTypeTone = normalized.copyWith(
        preferredTone: _toneFromStoryType(_storyType),
      );
      final businessErr = ChildProfileRules.validate(normalizedWithTypeTone);
      if (businessErr != null) {
        _showError(businessErr);
        return;
      }

      await ref.read(childProfileProvider.notifier).upsert(normalizedWithTypeTone);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingProfile = ref.watch(childProfileProvider);
    final years = List<int>.generate(18, (i) => DateTime.now().year - i);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Profil enfant',
          style: theme.textTheme.titleLarge?.copyWith(
            color: LunoraColors.warmBeige,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: LunoraScreenShell(
        showStarfield: true,
        starCount: 36,
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
                    Text(
                      'Renseigne le minimum. Elunai adapte automatiquement selon l’âge.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
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
                                  decoration: const InputDecoration(labelText: 'Mois'),
                                  items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}'))),
                                  onChanged: (v) => setState(() => _birthMonth = v ?? _birthMonth),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _birthYear,
                                  decoration: const InputDecoration(labelText: 'Année'),
                                  items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                                  onChanged: (v) => setState(() => _birthYear = v ?? _birthYear),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _language,
                            decoration: const InputDecoration(labelText: 'Langue de l’histoire'),
                            items: const [
                              DropdownMenuItem(value: 'fr', child: Text('Français')),
                              DropdownMenuItem(value: 'en', child: Text('Anglais')),
                            ],
                            onChanged: (v) => setState(() => _language = v ?? _language),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SectionCard(
                      title: 'Centres d interet',
                      subtitle: 'Optionnel',
                      child: Column(
                        children: [
                          LunoraTextField(
                            controller: _preferredThemes,
                            label: 'Interets (optionnel)',
                            hint: 'animaux, nature, espace',
                          ),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: const [
                              'animaux',
                              'nature',
                              'espace',
                              'amitie',
                              'musique',
                              'dinosaures',
                            ],
                            onSelected: (value) => _appendChipValue(_preferredThemes, value),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                      icon: Icon(
                        _showAdvanced ? Icons.expand_less_rounded : Icons.tune_rounded,
                      ),
                      label: Text(
                        _showAdvanced ? 'Masquer les options avancees' : 'Afficher les options avancees',
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    if (_showAdvanced) ...[
                    _SectionCard(
                      title: 'Options avancees',
                      subtitle: 'Type, duree, ambiance et parametrage fin.',
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _storyType,
                            decoration: const InputDecoration(labelText: 'Type d histoire'),
                            items: const [
                              DropdownMenuItem(value: 'soir', child: Text('Soir')),
                              DropdownMenuItem(value: 'aventure', child: Text('Aventure')),
                              DropdownMenuItem(value: 'educatif', child: Text('Educatif')),
                            ],
                            onChanged: (v) => setState(() => _storyType = v ?? _storyType),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<StoryFormat>(
                            value: _format,
                            decoration: const InputDecoration(labelText: 'Format narratif'),
                            items: const [
                              DropdownMenuItem(value: StoryFormat.dailyStandalone, child: Text('Histoire unique')),
                              DropdownMenuItem(value: StoryFormat.serializedChapters, child: Text('Série en chapitres')),
                            ],
                            onChanged: (v) => setState(() => _format = v ?? _format),
                          ),
                          const SizedBox(height: AppSizes.md),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 5, label: Text('5 min')),
                              ButtonSegment(value: 10, label: Text('10 min')),
                              ButtonSegment(value: 15, label: Text('15 min')),
                            ],
                            selected: {_storyMinutes},
                            onSelectionChanged: (Set<int> value) => setState(() => _storyMinutes = value.first),
                          ),
                          if (_format == StoryFormat.serializedChapters) ...[
                            const SizedBox(height: AppSizes.md),
                            DropdownButtonFormField<int>(
                              value: _seriesDays,
                              decoration: const InputDecoration(labelText: 'Durée de la série'),
                              items: const [
                                DropdownMenuItem(value: 3, child: Text('3 jours')),
                                DropdownMenuItem(value: 5, child: Text('5 jours')),
                                DropdownMenuItem(value: 7, child: Text('7 jours')),
                                DropdownMenuItem(value: 14, child: Text('14 jours')),
                              ],
                              onChanged: (v) => setState(() => _seriesDays = v ?? _seriesDays),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SectionCard(
                      title: 'Univers & ambiance',
                      subtitle: 'Option avancee',
                      child: Column(
                        children: [
                          DropdownButtonFormField<StoryTone>(
                            value: _tone,
                            decoration: const InputDecoration(labelText: 'Ton préféré'),
                            items: StoryTone.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayLabel))).toList(),
                            onChanged: (v) => setState(() => _tone = v ?? _tone),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<UniverseType>(
                            value: _universe,
                            decoration: const InputDecoration(labelText: 'Univers préféré'),
                            items: UniverseType.values.map((u) => DropdownMenuItem(value: u, child: Text(u.displayLabel))).toList(),
                            onChanged: (v) => setState(() => _universe = v ?? _universe),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _magicLevel,
                            decoration: const InputDecoration(labelText: 'Niveau de magie'),
                            items: const [
                              DropdownMenuItem(value: 'réaliste', child: Text('Réaliste')),
                              DropdownMenuItem(value: 'légèrement magique', child: Text('Légèrement magique')),
                              DropdownMenuItem(value: 'très magique', child: Text('Très magique')),
                            ],
                            onChanged: (v) => setState(() => _magicLevel = v ?? _magicLevel),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _adventureIntensity,
                            decoration: const InputDecoration(labelText: 'Intensité d’aventure'),
                            items: const [
                              DropdownMenuItem(value: 'très douce', child: Text('Très douce')),
                              DropdownMenuItem(value: 'équilibrée', child: Text('Équilibrée')),
                              DropdownMenuItem(value: 'aventureuse mais rassurante', child: Text('Aventureuse mais rassurante')),
                            ],
                            onChanged: (v) => setState(() => _adventureIntensity = v ?? _adventureIntensity),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    _SectionCard(
                      title: 'Préférences émotionnelles',
                      subtitle: 'Option avancee',
                      child: Column(
                        children: [
                          LunoraTextField(controller: _avoidThemes, label: 'Ce que vous préférez éviter', hint: 'monstres, danger'),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: const [
                              'monstres',
                              'noir',
                              'séparation',
                              'danger',
                              'orage',
                            ],
                            onSelected: (value) => _appendChipValue(_avoidThemes, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          LunoraTextField(controller: _personalityTraits, label: 'Traits de personnalité', hint: 'curieux, sensible'),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: const [
                              'curieux',
                              'timide',
                              'sensible',
                              'rêveur',
                              'créatif',
                              'drôle',
                            ],
                            onSelected: (value) => _appendChipValue(_personalityTraits, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          LunoraTextField(controller: _fears, label: 'Petites peurs à accompagner', hint: 'peur du noir, séparation'),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: const [
                              'peur du noir',
                              'peur de dormir seul',
                              'peur de l’école',
                              'peur de la séparation',
                            ],
                            onSelected: (value) => _appendChipValue(_fears, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          LunoraTextField(controller: _values, label: 'Valeurs à transmettre', hint: 'gentillesse, confiance'),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: const [
                              'gentillesse',
                              'patience',
                              'autonomie',
                              'confiance',
                              'partage',
                            ],
                            onSelected: (value) => _appendChipValue(_values, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _bedtimeEnergyLevel,
                            decoration: const InputDecoration(labelText: 'Niveau d’énergie avant coucher'),
                            items: const [
                              DropdownMenuItem(value: 'très calme', child: Text('Très calme')),
                              DropdownMenuItem(value: 'calme', child: Text('Calme')),
                              DropdownMenuItem(value: 'un peu dynamique', child: Text('Un peu dynamique')),
                              DropdownMenuItem(value: 'a besoin d’être apaisé', child: Text('A besoin d’être apaisé')),
                            ],
                            onChanged: (v) => setState(() => _bedtimeEnergyLevel = v ?? _bedtimeEnergyLevel),
                          ),
                          const SizedBox(height: AppSizes.md),
                          LunoraTextField(
                            controller: _familiarElements,
                            label: 'Éléments familiers à intégrer',
                            hint: 'maman, doudou, maison',
                          ),
                          const SizedBox(height: AppSizes.sm),
                          _ChipSuggestions(
                            options: const [
                              'maman',
                              'papa',
                              'doudou',
                              'animal de compagnie',
                              'maison',
                            ],
                            onSelected: (value) => _appendChipValue(_familiarElements, value),
                          ),
                          const SizedBox(height: AppSizes.md),
                          DropdownButtonFormField<String>(
                            value: _tonightGoal,
                            decoration: const InputDecoration(labelText: 'Objectif du soir'),
                            items: const [
                              DropdownMenuItem(value: 's’endormir calmement', child: Text('S’endormir calmement')),
                              DropdownMenuItem(value: 'se rassurer', child: Text('Se rassurer')),
                              DropdownMenuItem(value: 'rire un peu', child: Text('Rire un peu')),
                              DropdownMenuItem(value: 'apprendre quelque chose', child: Text('Apprendre quelque chose')),
                              DropdownMenuItem(value: 'prolonger une série', child: Text('Prolonger une série')),
                            ],
                            onChanged: (v) => setState(() => _tonightGoal = v ?? _tonightGoal),
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
                      MagicalAppButton(
                        label: 'Enregistrer',
                        icon: Icons.save_rounded,
                        onPressed: _submit,
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
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: LunoraColors.nightBlueLift.withValues(alpha: 0.55),
        border: Border.all(color: LunoraColors.mist.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: LunoraColors.warmBeige,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: LunoraColors.mist.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(height: AppSizes.md),
          child,
        ],
      ),
    );
  }
}

class _ChipSuggestions extends StatelessWidget {
  const _ChipSuggestions({
    required this.options,
    required this.onSelected,
  });

  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
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
              side: BorderSide(color: LunoraColors.mist.withValues(alpha: 0.2)),
            ),
            backgroundColor: LunoraColors.nightBlue.withValues(alpha: 0.45),
            labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: LunoraColors.warmBeige,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}
