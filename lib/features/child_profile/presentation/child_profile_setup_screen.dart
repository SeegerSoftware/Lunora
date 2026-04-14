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

  int _birthMonth = 6;
  int _birthYear = 2019;
  int _storyMinutes = 10;
  StoryFormat _format = StoryFormat.dailyStandalone;
  int _seriesDays = 7;
  StoryTone _tone = ChildProfileRules.defaultTone();
  UniverseType _universe = ChildProfileRules.defaultUniverseType();

  var _loading = false;

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
        _universe = existing.universeType;
        _preferredThemes.text = existing.preferredThemes.join(', ');
        _avoidThemes.text = existing.avoidThemes.join(', ');
        _personalityTraits.text = existing.personalityTraits.join(', ');
        _fears.text = existing.fearsToAddress.join(', ');
        _values.text = existing.valuesToTeach.join(', ');
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
    super.dispose();
  }

  List<String> _splitList(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: LunoraColors.nightSkyVertical),
          ),
          StarfieldBackground(
            starCount: 36,
            child: SafeArea(
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
                      'Quelques repères pour personnaliser les histoires du soir.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: LunoraColors.mist.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
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
                              labelText: 'Mois de naissance',
                            ),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text('${i + 1}'),
                              ),
                            ),
                            onChanged: (v) =>
                                setState(() => _birthMonth = v ?? _birthMonth),
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
                            onChanged: (v) =>
                                setState(() => _birthYear = v ?? _birthYear),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text('Durée moyenne', style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSizes.sm),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 5, label: Text('5 min')),
                        ButtonSegment(value: 10, label: Text('10 min')),
                        ButtonSegment(value: 15, label: Text('15 min')),
                      ],
                      selected: {_storyMinutes},
                      onSelectionChanged: (Set<int> value) {
                        setState(() => _storyMinutes = value.first);
                      },
                    ),
                    const SizedBox(height: AppSizes.md),
                    DropdownButtonFormField<StoryFormat>(
                      value: _format,
                      decoration: const InputDecoration(
                        labelText: 'Format narratif',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: StoryFormat.dailyStandalone,
                          child: Text('Histoire indépendante chaque jour'),
                        ),
                        DropdownMenuItem(
                          value: StoryFormat.serializedChapters,
                          child: Text('Série en chapitres'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _format = v ?? _format),
                    ),
                    if (_format == StoryFormat.serializedChapters) ...[
                      const SizedBox(height: AppSizes.md),
                      DropdownButtonFormField<int>(
                        value: _seriesDays,
                        decoration: const InputDecoration(
                          labelText: 'Durée de la série',
                        ),
                        items: const [
                          DropdownMenuItem(value: 7, child: Text('7 jours')),
                          DropdownMenuItem(value: 14, child: Text('14 jours')),
                          DropdownMenuItem(value: 21, child: Text('21 jours')),
                          DropdownMenuItem(value: 28, child: Text('28 jours')),
                        ],
                        onChanged: (v) =>
                            setState(() => _seriesDays = v ?? _seriesDays),
                      ),
                    ],
                    const SizedBox(height: AppSizes.md),
                    DropdownButtonFormField<StoryTone>(
                      value: _tone,
                      decoration: const InputDecoration(
                        labelText: 'Ton préféré',
                      ),
                      items: StoryTone.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _tone = v ?? _tone),
                    ),
                    const SizedBox(height: AppSizes.md),
                    DropdownButtonFormField<UniverseType>(
                      value: _universe,
                      decoration: const InputDecoration(
                        labelText: 'Univers préféré',
                      ),
                      items: UniverseType.values
                          .map(
                            (u) => DropdownMenuItem(
                              value: u,
                              child: Text(u.displayLabel),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _universe = v ?? _universe),
                    ),
                    const SizedBox(height: AppSizes.md),
                    LunoraTextField(
                      controller: _preferredThemes,
                      label: 'Thèmes préférés',
                      hint: 'Ex : étoiles, animaux doux',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.md),
                    LunoraTextField(
                      controller: _avoidThemes,
                      label: 'Thèmes à éviter',
                      hint: 'Ex : monstres, tempête',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.md),
                    LunoraTextField(
                      controller: _personalityTraits,
                      label: 'Traits de personnalité',
                      hint: 'Ex : curieux, sensible',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.md),
                    LunoraTextField(
                      controller: _fears,
                      label: 'Peurs à adoucir',
                      hint: 'Ex : le noir, la séparation',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSizes.md),
                    LunoraTextField(
                      controller: _values,
                      label: 'Valeurs à transmettre',
                      hint: 'Ex : confiance, gentillesse',
                      textInputAction: TextInputAction.done,
                    ),
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
        ],
      ),
    );
  }
}
