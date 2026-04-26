import '../../shared/models/child_profile.dart';
import '../../shared/models/story_universe.dart';

/// Modération locale des textes liés aux histoires (0–12 ans).
///
/// Complémentaire à tout filtrage serveur : bloque injonctions, contenus
/// adultes/violents évidents et limites les abus de longueur.
abstract final class StoryProfileModeration {
  static const int maxFirstNameLength = 40;
  static const int maxExtraHintsLength = 2000;
  static const int maxSingleListEntryLength = 120;
  static const int maxTotalProfileTextLength = 12000;

  /// Texte combiné pour analyse (prénom, thèmes, notes, etc.).
  static String flattenProfileText(ChildProfile p) {
    final b = StringBuffer()
      ..write(p.firstName)
      ..write(' ')
      ..write(p.extraStoryHints)
      ..write(' ')
      ..write(p.preferredUniverse)
      ..write(' ')
      ..write(p.storyUniverse.meta.moderationSnippet)
      ..write(' ')
      ..write(p.magicLevel)
      ..write(' ')
      ..write(p.adventureIntensity)
      ..write(' ')
      ..write(p.bedtimeEnergyLevel)
      ..write(' ')
      ..write(p.tonightGoal)
      ..write(' ')
      ..writeAll(p.preferredThemes, ' ')
      ..write(' ')
      ..writeAll(p.personalityTraits, ' ')
      ..write(' ')
      ..writeAll(p.avoidThemes, ' ')
      ..write(' ')
      ..writeAll(p.fearsToAddress, ' ')
      ..write(' ')
      ..writeAll(p.softenedFears, ' ')
      ..write(' ')
      ..writeAll(p.valuesToTeach, ' ')
      ..write(' ')
      ..writeAll(p.valuesToTransmit, ' ')
      ..write(' ')
      ..writeAll(p.familiarElements, ' ');
    return b.toString();
  }

  /// `null` si OK, sinon message d’erreur pour l’utilisateur.
  static String? validateChildProfile(ChildProfile p) {
    final name = p.firstName.trim();
    if (name.isEmpty) return null;
    if (name.length > maxFirstNameLength) {
      return 'Prénom trop long ($maxFirstNameLength caractères maximum).';
    }
    if (p.extraStoryHints.length > maxExtraHintsLength) {
      return 'Les notes libres dépassent la limite ($maxExtraHintsLength caractères).';
    }
    for (final list in <List<String>>[
      p.preferredThemes,
      p.personalityTraits,
      p.avoidThemes,
      p.fearsToAddress,
      p.softenedFears,
      p.valuesToTeach,
      p.valuesToTransmit,
      p.familiarElements,
    ]) {
      for (final e in list) {
        if (e.trim().length > maxSingleListEntryLength) {
          return 'Une entrée est trop longue ($maxSingleListEntryLength caractères max par idée).';
        }
      }
    }
    final flat = flattenProfileText(p);
    if (flat.length > maxTotalProfileTextLength) {
      return 'Trop de texte au total dans le profil. Merci de raccourcir.';
    }
    if (containsDisallowedContent(flat)) {
      return 'Certains mots ou formulations ne sont pas adaptés aux histoires pour enfants '
          '(violence, contenu adulte, injonctions au système, etc.).';
    }
    return null;
  }

  /// Vérifie un texte libre (ex. sortie LLM) avec la même liste que le profil.
  static bool containsDisallowedContent(String raw) {
    final h = foldAscii(raw);
    if (h.isEmpty) return false;
    for (final p in _blockedPhrases) {
      if (h.contains(p)) return true;
    }
    for (final w in _blockedWholeWords) {
      if (RegExp(r'\b' + RegExp.escape(w) + r'\b').hasMatch(h)) return true;
    }
    return false;
  }

  /// Normalisation pour comparaison (public pour réutilisation côté sortie).
  static String foldAscii(String s) {
    return s
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
        .replaceAll('`', "'");
  }

  /// Phrases / expressions (déjà repliées en ASCII minuscule).
  static const List<String> _blockedPhrases = <String>[
    // Contournement modèle / prompt
    'ignore all previous',
    'ignore previous instructions',
    'ignore the above',
    'disregard previous',
    'system prompt',
    'developer message',
    'you are now',
    'tu es maintenant',
    'nouvelle instruction',
    'sans restriction',
    'sans limite',
    'sans limites',
    'contourne les regles',
    'contourner les regles',
    'contourne la moderation',
    'jailbreak',
    'dan mode',
    'roleplay adulte',
    'rp +18',
    'mode nsfw',
    'prompt injection',
    'reveal your',
    'affiche ta consigne',
    // Sexualité / adulte
    'scene de sexe',
    'scene sexuelle',
    'contenu adulte',
    'contenu pornographique',
    'histoire erotique',
    'recit erotique',
    'nu integral',
    'nue integral',
    'sexe explicite',
    'acte sexuel',
    'pedophil',
    'pornograph',
    'hentai',
    'onlyfans',
    'escort service',
    // Violence forte
    'decapitation',
    'saigner a mort',
    'comment fabriquer une arme',
    'comment se suicider',
    'methode pour se suicider',
    // Drogues dures (évidents)
    'cocaine',
    'heroin inject',
    'methamphetamine',
    'fentanyl',
    // Haine / extrémisme (formulations fréquentes)
    'solution finale',
    'ethnic cleansing',
  ];

  /// Mots courts dangereux (frontière de mot).
  static const List<String> _blockedWholeWords = <String>[
    'porn',
    'xxx',
    'nsfw',
    'nazi',
    'hitler',
    'suicide',
    'suicidaire',
    'sodomie',
    'viol',
    'violer',
    'inceste',
    'pedophile',
    'pedoporn',
    'tuer',
    'meurtre',
    'meurtrier',
    'torture',
    'massacre',
    'egorger',
    'arme',
    'fusil',
    'pistolet',
    'kalachnikov',
    'bombe',
    'explosif',
    'cannabis',
    'heroin',
    'cocaine',
    'meth',
    'shota',
    'loli',
    'rape',
    'raped',
    'raping',
    'nude',
    'nudes',
    'fuck',
    'shit',
    'bitch',
    'slut',
    'whore',
    'cum',
    'dick',
    'cock',
    'pussy',
    'anus',
    'penis',
    'vagin',
    'clitoris',
    'orgasme',
    'masturb',
    'ejacul',
    'sperme',
    'strip-tease',
    'strip tease',
    'prostitu',
    'escort',
    'hardcore',
    'snuff',
    'gore',
    'guro',
  ];
}
