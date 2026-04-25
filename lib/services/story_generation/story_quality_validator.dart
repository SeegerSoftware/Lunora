import 'story_quality_result.dart';

/// Heuristiques locales : pas d’appel réseau, pas de LLM.
class StoryQualityValidator {
  const StoryQualityValidator();

  static const int validThreshold = 70;

  /// [story] : texte complet évalué (ex. titre + corps).
  StoryQualityResult evaluate({
    required String story,
    required String childName,
    required int targetMinutes,
  }) {
    final text = story.trim();
    final issues = <String>[];

    final words = _tokenizeWords(text);
    final wordCount = words.length;

    final lengthPts = _scoreLength(
      wordCount: wordCount,
      targetMinutes: targetMinutes,
      issues: issues,
    );
    final namePts = _scoreName(
      text: text,
      childName: childName,
      issues: issues,
    );
    final structurePts = _scoreStructure(
      text: text,
      words: words,
      issues: issues,
    );
    final fluencyPts = _scoreFluency(
      words: words,
      issues: issues,
    );
    final tonePts = _scoreTone(
      text: text,
      issues: issues,
    );
    final endingPts = _scoreEnding(
      text: text,
      issues: issues,
    );
    final narrativePts = _scoreNarrativeRequirements(
      text: text,
      issues: issues,
    );
    final profilePts = _scoreProfileEcho(
      text: text,
      issues: issues,
    );

    final guardPassed = _hasNarrativeGuard(text, issues);

    final total = (lengthPts +
            namePts +
            structurePts +
            fluencyPts +
            tonePts +
            endingPts +
            narrativePts +
            profilePts)
        .clamp(0, 100);

    return StoryQualityResult(
      score: total,
      isValid: total >= validThreshold && guardPassed,
      issues: List.unmodifiable(issues),
      lengthPoints: lengthPts,
      namePoints: namePts,
      structurePoints: structurePts,
      fluencyPoints: fluencyPts,
      tonePoints: tonePts,
      endingPoints: endingPts,
      narrativePoints: narrativePts,
      profilePoints: profilePts,
      narrativeGuardPassed: guardPassed,
    );
  }

  /// Longueur : cible ≈ [targetMinutes] × 100 mots, ±30 % (15 pts).
  static int _scoreLength({
    required int wordCount,
    required int targetMinutes,
    required List<String> issues,
  }) {
    final target = (targetMinutes * 100).clamp(50, 5000);
    final low = (target * 0.7).round();
    final high = (target * 1.3).round();

    if (wordCount >= low && wordCount <= high) {
      return 15;
    }
    if (wordCount < low) {
      issues.add(
        'Longueur: $wordCount mots (cible ~$target, min toléré $low).',
      );
      final ratio = wordCount / low;
      return (15 * ratio).round().clamp(0, 14);
    }
    issues.add(
      'Longueur: $wordCount mots (cible ~$target, max toléré $high).',
    );
    final ratio = high / wordCount;
    return (15 * ratio).round().clamp(0, 14);
  }

  /// Prénom présent dans le texte (10 pts).
  static int _scoreName({
    required String text,
    required String childName,
    required List<String> issues,
  }) {
    final name = childName.trim();
    if (name.isEmpty || name == 'l’enfant' || name.toLowerCase() == 'enfant') {
      return 10;
    }
    final hay = _foldAccents(text.toLowerCase());
    final needle = _foldAccents(name.toLowerCase());
    if (hay.contains(needle)) {
      return 10;
    }
    issues.add('Prénom "$name" absent ou non détecté dans le texte.');
    return 0;
  }

  /// Structure narrative implicite (15 pts).
  static int _scoreStructure({
    required String text,
    required List<String> words,
    required List<String> issues,
  }) {
    final sentences = _splitSentences(text);
    var pts = 0;

    if (sentences.length >= 5) {
      pts += 10;
    } else {
      issues.add(
        'Structure: peu de phrases (${sentences.length}), attendu au moins 5.',
      );
      pts += (10 * sentences.length / 5).round().clamp(0, 9);
    }

    if (words.length >= 40) {
      final n = words.length;
      final t1 = n ~/ 3;
      final t2 = (2 * n) ~/ 3;
      final first = words.sublist(0, t1).length;
      final mid = words.sublist(t1, t2).length;
      final last = words.sublist(t2).length;
      if (first >= 12 && mid >= 18 && last >= 8) {
        pts += 10;
      } else {
        issues.add(
          'Structure: répartition début / milieu / fin peu équilibrée.',
        );
        pts += 5;
      }
    } else {
      issues.add('Structure: texte trop court pour une progression claire.');
    }

    return pts.clamp(0, 15);
  }

  /// Répétitions / fluidité via ratio mots uniques (10 pts).
  static int _scoreFluency({
    required List<String> words,
    required List<String> issues,
  }) {
    if (words.isEmpty) return 0;
    final unique = words.toSet().length;
    final ratio = unique / words.length;

    if (ratio >= 0.42) return 10;
    if (ratio >= 0.35) {
      issues.add('Fluidité: vocabulaire un peu répétitif (ratio $ratio).');
      return 7;
    }
    if (ratio >= 0.28) {
      issues.add('Fluidité: répétitions notables (ratio $ratio).');
      return 4;
    }
    issues.add('Fluidité: répétitions excessives (ratio $ratio).');
    return 1;
  }

  static const _toneBlacklist = {
    'peur',
    'danger',
    'monstre',
    'hurle',
    'crie',
    'attaque',
  };

  /// Ton apaisant : mots à éviter (15 pts).
  static int _scoreTone({
    required String text,
    required List<String> issues,
  }) {
    final tokens = _tokenizeWords(text);
    var hits = 0;
    for (final w in tokens) {
      if (_toneBlacklist.contains(w)) hits++;
    }
    if (hits == 0) return 15;
    issues.add(
      'Ton: $hits mot(s) marquant(s) peu adaptés au coucher (liste noire).',
    );
    return (15 - hits * 5).clamp(0, 15);
  }

  static const _endingKeywords = {
    'dormir',
    'endormir',
    's’endormir',
    "s'endormir",
    'calme',
    'doucement',
    'nuit',
    'sommeil',
    'rêve',
    'reve',
    'berceuse',
    'silence',
    'douce',
    'paix',
    'repos',
  };

  /// Qualité de fin : dernière portion du texte (15 pts).
  static int _scoreEnding({
    required String text,
    required List<String> issues,
  }) {
    if (text.length < 40) {
      issues.add('Fin: texte trop court pour évaluer la clôture.');
      return 0;
    }
    final tailLen = (text.length * 0.25).ceil().clamp(120, 900);
    final tail = text.substring(text.length - tailLen).toLowerCase();
    final folded = _foldAccents(tail);

    var matches = 0;
    for (final kw in _endingKeywords) {
      if (folded.contains(_foldAccents(kw.toLowerCase()))) {
        matches++;
      }
    }

    if (matches >= 2) return 15;
    if (matches == 1) {
      issues.add('Fin: une seule accroche de clôture douce détectée.');
      return 9;
    }
    issues.add(
      'Fin: peu d’indices de fermeture apaisante (dormir, nuit, calme…).',
    );
    return 3;
  }

  static int _scoreNarrativeRequirements({
    required String text,
    required List<String> issues,
  }) {
    final folded = _foldAccents(text.toLowerCase());
    var score = 0;

    final perturbation = RegExp(
      r'\b(mais|soudain|hesite|hesitation|ne savait pas|petit souci|doute)\b',
    ).hasMatch(folded);
    if (perturbation) {
      score += 6;
    } else {
      issues.add('Narration: élément perturbateur doux peu détecté.');
    }

    final resolution = RegExp(
      r'\b(finalement|peu a peu|se rassure|se calma|tout alla mieux|comprit)\b',
    ).hasMatch(folded);
    if (resolution) {
      score += 6;
    } else {
      issues.add('Narration: résolution rassurante peu détectée.');
    }

    final dialogue = text.contains('«') || text.contains('"');
    if (dialogue) {
      score += 4;
    } else {
      issues.add('Narration: aucun dialogue détecté.');
    }

    final transformation = RegExp(
      r'\b(au debut|au début|a la fin|desormais|desormais|plus confiant|avait appris)\b',
    ).hasMatch(folded);
    if (transformation) {
      score += 4;
    } else {
      issues.add('Narration: transformation émotionnelle peu explicite.');
    }

    return score.clamp(0, 20);
  }

  static int _scoreProfileEcho({
    required String text,
    required List<String> issues,
  }) {
    final folded = _foldAccents(text.toLowerCase());
    const profileSignals = [
      'curieux',
      'timide',
      'sensible',
      'courage',
      'confiance',
      'partage',
      'peur du noir',
      'rassure',
      's endormir',
      'objectif',
    ];
    var hits = 0;
    for (final s in profileSignals) {
      if (folded.contains(_foldAccents(s))) hits++;
    }
    if (hits >= 3) return 10;
    if (hits >= 2) return 7;
    if (hits >= 1) {
      issues.add('Profil: personnalisation encore légère.');
      return 4;
    }
    issues.add('Profil: peu de signaux de personnalisation détectés.');
    return 1;
  }

  static bool _hasNarrativeGuard(String text, List<String> issues) {
    final folded = _foldAccents(text.toLowerCase());
    final hasPerturbation = RegExp(
      r'\b(mais|soudain|hesite|doute|petit souci)\b',
    ).hasMatch(folded);
    final hasResolution = RegExp(
      r'\b(finalement|peu a peu|se calma|se rassura|tout alla mieux)\b',
    ).hasMatch(folded);
    if (!hasPerturbation || !hasResolution) {
      issues.add('Guard: progression narrative incomplète (perturbation/résolution).');
      return false;
    }
    return true;
  }

  static final RegExp _stripEdges = RegExp(
    r'''^[^0-9a-zA-ZàâäéèêëïîôùûüçœæÀÂÄÉÈÊËÏÎÔÙÛÜÇŒÆ'-]+|[^0-9a-zA-ZàâäéèêëïîôùûüçœæÀÂÄÉÈÊËÏÎÔÙÛÜÇŒÆ'-]+$''',
    unicode: true,
  );

  static List<String> _tokenizeWords(String text) {
    final normalized = text.replaceAll(RegExp(r'[\u2019\u2018]'), "'");
    return normalized
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(_stripEdges, ''))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'[.!?…]+'))
        .map((s) => s.trim())
        .where((s) => s.length > 8)
        .toList();
  }

  static String _foldAccents(String input) {
    const from = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñœæ';
    const to = 'aaaaaaeeeeiiiiooooouuuuyycnae';
    final buf = StringBuffer();
    for (final ch in input.runes) {
      final c = String.fromCharCode(ch);
      final i = from.indexOf(c);
      if (i >= 0) {
        buf.write(to[i]);
      } else {
        buf.write(c);
      }
    }
    return buf.toString();
  }
}
