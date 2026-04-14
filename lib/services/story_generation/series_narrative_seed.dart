import '../../shared/models/child_profile.dart';
import '../../shared/models/enums/universe_type.dart';
import '../../shared/models/story.dart';

/// Éléments stables du « fil rouge » d’une série (compagnon, objet, quête douce).
class SeriesNarrativeBundle {
  const SeriesNarrativeBundle({
    required this.companion,
    required this.magicObject,
    required this.globalObjective,
  });

  final String companion;
  final String magicObject;
  final String globalObjective;
}

/// Génération déterministe + formatage prompt (Firestore ou mock conserve les valeurs).
abstract final class SeriesNarrativeSeed {
  static const _companions = <String>[
    'un petit renard des bois au cœur tendre',
    'une luciole fidèle qui veille sans bruit',
    'un chaton au pelage argenté et curieux',
    'un hibou sage qui parle tout bas',
    'une petite souris voyageuse et généreuse',
    'un lapin à l’oreille attentive',
    'une chouette en peluche imaginaire qui sourit',
  ];

  static const _magicObjects = <String>[
    'une pierre lunaire qui brille doucement au creux de la main',
    'un foulard aux bords étoilés qui réchauffe les idées',
    'une clochette qui tinte une mélodie calme',
    'un carnet dont les pages murmurent des souvenirs doux',
    'une lentille de verre qui rend le monde plus tendre',
    'une lanterne aux reflets ambrés',
    'un coquillage qui retient le murmure de la mer',
  ];

  static const _globalGoals = <String>[
    'retrouver la confiance avant de s’endormir',
    'apprendre à partager la chaleur avec les autres',
    'guider son courage pas à pas, sans se presser',
    'découvrir que la peur diminue quand on la nomme à voix basse',
    'apporter une petite lumière là où il fait un peu sombre',
    'construire un pont doux entre le jour et la nuit',
    'accueillir les émotions avec douceur et les laisser passer',
  ];

  /// Toujours identique pour un même [seriesId] (et prénom comme sel secondaire).
  static SeriesNarrativeBundle generate(
    String seriesId, {
    String firstName = '',
  }) {
    final h = Object.hash(seriesId, firstName).abs();
    return SeriesNarrativeBundle(
      companion: _companions[h % _companions.length],
      magicObject: _magicObjects[(h ~/ 7) % _magicObjects.length],
      globalObjective: _globalGoals[(h ~/ 13) % _globalGoals.length],
    );
  }

  static String formatFilRougeBlock(SeriesNarrativeBundle b) {
    return '''
Éléments récurrents de la série :
- compagnon : ${b.companion}
- objet spécial : ${b.magicObject}
- objectif global : ${b.globalObjective}
'''
        .trim();
  }

  /// [previousChaptersSorted] : chapitres déjà publiés, triés par numéro croissant.
  static String structuredContinuity({
    required ChildProfile child,
    required List<Story> previousChaptersSorted,
    required String seriesGlobalObjective,
  }) {
    if (previousChaptersSorted.isEmpty) return '';

    final last = previousChaptersSorted.last;
    final hero = child.firstName.trim().isEmpty
        ? 'l’enfant (héros / héroïne de l’histoire)'
        : '${child.firstName.trim()} (héros / héroïne de l’histoire)';

    final situation = last.summary.trim().isNotEmpty
        ? 'après le chapitre ${last.chapterNumber} (« ${last.title.trim()} »), ${last.summary.trim()}'
        : 'après le chapitre ${last.chapterNumber} (« ${last.title.trim()} »).';

    final excerpt = _shortExcerpt(last.content, 220);

    return '''
Résumé des chapitres précédents :
- Personnage principal : $hero
- Univers : ${child.universeType.displayLabel}
- Situation actuelle : $situation
- Objectif : $seriesGlobalObjective
- Dernier événement : « ${last.title.trim()} » — $excerpt
'''
        .trim();
  }

  static String _shortExcerpt(String content, int max) {
    final t = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max)}…';
  }
}
