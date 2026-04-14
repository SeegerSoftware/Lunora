import '../../../services/story_generation/series_narrative_seed.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/enums/story_tone.dart';
import '../../../shared/models/enums/universe_type.dart';
import '../../../shared/models/user_model.dart';
import '../domain/story_world.dart';

/// Crée un [StoryWorld] stable pour un enfant (déterministe, pas d’aléa runtime).
abstract final class StoryWorldSeed {
  static const _worldNames = <String>[
    'Le pays des souffles doux',
    'Le royaume du couchant calme',
    'Les terres du petit sommeil',
    'La vallée des lanternes patientes',
    'L’île aux murmures bienveillants',
    'Le jardin des étoiles basses',
  ];

  static StoryWorld initial({
    required ChildProfile child,
    required UserModel user,
    String? legacyCompanion,
    String? legacyMagicItem,
    String? legacyCoreGoal,
  }) {
    final now = DateTime.now();
    final h = Object.hash(child.id, child.firstName).abs();
    final bundle = SeriesNarrativeSeed.generate(
      'series_${child.id}',
      firstName: child.firstName,
    );

    final companion =
        (legacyCompanion != null && legacyCompanion.trim().isNotEmpty)
        ? legacyCompanion.trim()
        : bundle.companion;
    final magic =
        (legacyMagicItem != null && legacyMagicItem.trim().isNotEmpty)
        ? legacyMagicItem.trim()
        : bundle.magicObject;
    final goal =
        (legacyCoreGoal != null && legacyCoreGoal.trim().isNotEmpty)
        ? legacyCoreGoal.trim()
        : bundle.globalObjective;

    final worldName = _worldNames[h % _worldNames.length];

    return StoryWorld(
      id: child.id,
      childId: child.id,
      userId: user.id,
      worldName: worldName,
      mainCompanion: companion,
      magicItem: magic,
      coreGoal: goal,
      recurringPlaces: _recurringPlaces(child, h),
      worldTone: child.preferredTone.displayLabel,
      currentState:
          'L’univers « $worldName » s’ouvre doucement autour de ${child.firstName.trim().isEmpty ? "l’enfant" : child.firstName.trim()}.',
      currentArc: child.storyFormat == StoryFormat.serializedChapters
          ? 'Série en cours · installation de l’arc'
          : 'Histoires du soir · continuité douce',
      recentlyUsedElements: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<String> _recurringPlaces(ChildProfile child, int h) {
    final u = child.universeType;
    final pools = <UniverseType, List<String>>{
      UniverseType.forest: [
        'le sentier des mousses',
        'la clairière aux lucioles',
        'le ruisseau qui chuchote',
      ],
      UniverseType.ocean: [
        'la plage du soir',
        'la vague qui berce',
        'la coquille du silence',
      ],
      UniverseType.skyAndStars: [
        'le balcon des étoiles',
        'le nuage coussin',
        'la comète patiente',
      ],
      UniverseType.smallVillage: [
        'la place du puits',
        'la rue aux volets clos',
        'le jardin du voisin sage',
      ],
      UniverseType.imaginaryKingdom: [
        'le pont des drapeaux doux',
        'la salle des coussins royaux',
        'la tour qui veille sans bruit',
      ],
    };
    final list = pools[u] ?? pools[UniverseType.skyAndStars]!;
    final out = <String>[];
    for (var i = 0; i < list.length; i++) {
      out.add(list[(h + i) % list.length]);
    }
    return out;
  }
}