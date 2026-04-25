import '../../core/utils/age_calculator.dart';
import '../../shared/models/child_profile.dart';

enum StoryAgeBand { infant, earlyChildhood, middleChildhood, preteen }

class StoryAdaptationProfile {
  const StoryAdaptationProfile({
    required this.ageYears,
    required this.ageBand,
    required this.targetWordsMin,
    required this.targetWordsMax,
    required this.requiredStructure,
    required this.requiredComponents,
    required this.forbiddenElements,
    required this.endingGuidance,
    required this.vocabularyGuidance,
    required this.narrativeComplexity,
    required this.pacingGuidance,
    required this.parentInteractionHint,
    required this.readerFontScale,
    required this.preferPagination,
  });

  final int ageYears;
  final StoryAgeBand ageBand;
  final int targetWordsMin;
  final int targetWordsMax;
  final List<String> requiredStructure;
  final List<String> requiredComponents;
  final List<String> forbiddenElements;
  final String endingGuidance;
  final String vocabularyGuidance;
  final String narrativeComplexity;
  final String pacingGuidance;
  final String parentInteractionHint;
  final double readerFontScale;
  final bool preferPagination;
}

class StoryAdaptationEngine {
  const StoryAdaptationEngine();

  StoryAdaptationProfile fromChildProfile(ChildProfile child) {
    final ageYears = AgeCalculator.ageInYears(
      birthMonth: child.birthMonth,
      birthYear: child.birthYear,
    );
    return fromAge(
      ageYears: ageYears,
      requestedMinutes: child.storyLengthMinutes,
    );
  }

  StoryAdaptationProfile fromAge({
    required int ageYears,
    required int requestedMinutes,
  }) {
    final safeAge = ageYears.clamp(0, 12);
    final range = _wordRangeForAgeAndMinutes(
      ageBand: _ageBandFromYears(safeAge),
      requestedMinutes: requestedMinutes,
    );
    if (safeAge <= 2) {
      return StoryAdaptationProfile(
        ageYears: safeAge,
        ageBand: StoryAgeBand.infant,
        targetWordsMin: range.$1,
        targetWordsMax: range.$2,
        requiredStructure: const [
          'micro-sequences repetitives',
          'interactions parent-enfant',
          'cloture douce',
        ],
        requiredComponents: const [
          'sons simples (chut, dodo, doux)',
          'actions concretes tres simples',
          'questions courtes d interaction',
        ],
        forbiddenElements: const [
          'phrases longues',
          'concepts abstraits',
          'intrigue complexe',
        ],
        endingGuidance: 'fin tres douce et repetitive, orientee apaisement',
        vocabularyGuidance: 'mots tres simples, concrets et repetitifs',
        narrativeComplexity: 'micro-scenes lineaires sans sous-intrigue',
        pacingGuidance: 'rythme tres lent, repetitions et pauses frequentes',
        parentInteractionHint: 'inviter des interactions parent/enfant courtes',
        readerFontScale: 1.15,
        preferPagination: false,
      );
    }
    if (safeAge <= 5) {
      return StoryAdaptationProfile(
        ageYears: safeAge,
        ageBand: StoryAgeBand.earlyChildhood,
        targetWordsMin: range.$1,
        targetWordsMax: range.$2,
        requiredStructure: const [
          'debut calme',
          'petit evenement declencheur',
          'mini exploration',
          'retour',
          'fin apaisante',
        ],
        requiredComponents: const [
          'personnages clairs',
          'emotions simples',
          'univers magique doux',
        ],
        forbiddenElements: const [
          'intrigue complexe',
          'sous-histoires multiples',
          'tension forte',
        ],
        endingGuidance: 'endormissement doux et rassurant',
        vocabularyGuidance: 'phrases simples, vocabulaire usuel et rassurant',
        narrativeComplexity: 'structure courte avec personnages clairs',
        pacingGuidance: 'rythme lent et stable, transitions explicites',
        parentInteractionHint: 'laisser de petites pauses pour la voix du parent',
        readerFontScale: 1.08,
        preferPagination: false,
      );
    }
    if (safeAge <= 8) {
      return StoryAdaptationProfile(
        ageYears: safeAge,
        ageBand: StoryAgeBand.middleChildhood,
        targetWordsMin: range.$1,
        targetWordsMax: range.$2,
        requiredStructure: const [
          'introduction',
          'declencheur',
          'exploration',
          'petit probleme',
          'resolution',
          'retour calme',
        ],
        requiredComponents: const [
          'debut d intrigue',
          'legere tension',
          'resolution rassurante',
        ],
        forbiddenElements: const [
          'histoire plate',
          'absence de probleme',
          'vocabulaire trop abstrait',
        ],
        endingGuidance: 'retour au calme present mais non excessif',
        vocabularyGuidance: 'vocabulaire enrichi mais accessible',
        narrativeComplexity: 'mini-intrigue avec etapes claires',
        pacingGuidance: 'rythme modere qui ralentit fortement en fin',
        parentInteractionHint: 'quelques dialogues expressifs a lire a voix haute',
        readerFontScale: 1.0,
        preferPagination: true,
      );
    }
    return StoryAdaptationProfile(
      ageYears: safeAge,
      ageBand: StoryAgeBand.preteen,
      targetWordsMin: range.$1,
      targetWordsMax: range.$2,
      requiredStructure: const [
        'introduction immersive',
        'element declencheur clair',
        'developpement avec progression',
        'enjeu concret obligatoire',
        'tentative et reflexion du heros',
        'resolution',
        'conclusion avec emotion ou ouverture',
      ],
      requiredComponents: const [
        'probleme concret et tension legere reelle',
        'dialogues naturels',
        'decision du heros et evolution',
        'alternance narration / action / dialogue',
      ],
      forbiddenElements: const [
        'ton infantilisant',
        'repetitions excessives',
        'histoire contemplative sans objectif',
        'fin bebe sommeil',
      ],
      endingGuidance:
          'conclusion satisfaisante avec emotion ou ouverture imaginaire, sans repetition hypnotique',
      vocabularyGuidance: 'vocabulaire developpe, toujours clair',
      narrativeComplexity: 'histoire structuree, immersive, avec intrigue credible',
      pacingGuidance: 'rythme dynamique mais fluide, sans monotonie',
      parentInteractionHint: 'narration fluide proche d un roman jeunesse court',
      readerFontScale: 0.92,
      preferPagination: true,
    );
  }

  StoryAgeBand _ageBandFromYears(int ageYears) {
    if (ageYears <= 2) return StoryAgeBand.infant;
    if (ageYears <= 5) return StoryAgeBand.earlyChildhood;
    if (ageYears <= 8) return StoryAgeBand.middleChildhood;
    return StoryAgeBand.preteen;
  }

  (int, int) _wordRangeForAgeAndMinutes({
    required StoryAgeBand ageBand,
    required int requestedMinutes,
  }) {
    final base10 = switch (ageBand) {
      StoryAgeBand.infant => (200, 400),
      StoryAgeBand.earlyChildhood => (400, 700),
      StoryAgeBand.middleChildhood => (700, 1000),
      StoryAgeBand.preteen => (900, 1300),
    };
    switch (requestedMinutes) {
      case 5:
        return (_scaled(base10.$1, 0.7), _scaled(base10.$2, 0.7));
      case 15:
        return (_scaled(base10.$1, 1.3), _scaled(base10.$2, 1.3));
      case 10:
      default:
        return base10;
    }
  }

  int minWordsForValidation({
    required int ageYears,
    required int requestedMinutes,
  }) {
    final profile = fromAge(ageYears: ageYears, requestedMinutes: requestedMinutes);
    return profile.targetWordsMin;
  }

  int _scaled(int value, double factor) {
    return (value * factor).round();
  }
}
