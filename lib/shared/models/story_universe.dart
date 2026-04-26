import 'package:flutter/material.dart';

/// Huit univers éditoriaux (histoires du soir 3–8 ans).
enum StoryUniverse {
  magicAndFairy,
  animals,
  adventure,
  enchantedNature,
  ocean,
  space,
  dinosaurs,
  everydayMagic,
}

/// Métadonnées affichées + données pour prompts / graines narratives.
@immutable
class StoryUniverseMeta {
  const StoryUniverseMeta({
    required this.id,
    required this.displayName,
    required this.parentDescription,
    required this.emoji,
    required this.accentColor,
    required this.subUniverses,
    required this.narrativeTags,
  });

  final StoryUniverse id;
  final String displayName;
  /// Une ligne pour le parent (sous le titre dans l’UI).
  final String parentDescription;
  final String emoji;
  /// Couleur d’accent douce (bordures, pastilles).
  final Color accentColor;
  /// Sous-univers : variations thématiques à piocher pour l’IA.
  final List<String> subUniverses;
  /// Tags d’ambiance / rythme pour guider le LLM.
  final List<String> narrativeTags;

  String get wireValue => id.name;

  /// Bloc compact pour prompts système / utilisateur.
  String get promptBlock {
    final subs = subUniverses.join(' · ');
    final tags = narrativeTags.join(', ');
    return '''
Univers : $emoji $displayName
Résumé pour le parent : $parentDescription
Sous-univers (t’en inspires sans tout utiliser) : $subs
Ambiance & tags narratifs : $tags'''.trim();
  }

  /// Texte ajouté à la modération (profil aplati).
  String get moderationSnippet =>
      '$displayName $parentDescription ${subUniverses.join(" ")} ${narrativeTags.join(" ")}';
}

/// Catalogue unique — à garder aligné produit / marketing.
abstract final class StoryUniverseCatalog {
  static const Map<StoryUniverse, StoryUniverseMeta> all = {
    StoryUniverse.magicAndFairy: StoryUniverseMeta(
      id: StoryUniverse.magicAndFairy,
      displayName: 'Magie & féerie',
      parentDescription:
          'Baguettes douces, fées bienveillantes et petits enchantements sans danger.',
      emoji: '✨',
      accentColor: Color(0xFFB8A4D9),
      subUniverses: [
        'Château de nuages roses',
        'Baguette qui fait des bulles de rire',
        'Licorne paresseuse au pré de satin',
        'Potions qui sentent la vanille',
        'Parchemins qui chantent tout bas',
      ],
      narrativeTags: [
        'féérie lumineuse',
        'magie douce',
        'rythme lent',
        'merveille sans peur',
        'paillettes apaisantes',
      ],
    ),
    StoryUniverse.animals: StoryUniverseMeta(
      id: StoryUniverse.animals,
      displayName: 'Animaux',
      parentDescription:
          'Compagnons poilus ou à plumes, toujours gentils et rassurants.',
      emoji: '🦊',
      accentColor: Color(0xFF8FB8A3),
      subUniverses: [
        'Renard curieux au pelage chaud',
        'Hibou sage sur une branche coussin',
        'Lapin duveteux et timide',
        'Baleine berceuse sous les vagues calmes',
        'Chat qui ronronne comme une couette',
      ],
      narrativeTags: [
        'tendresse animale',
        'complicité douce',
        'bruits apaisants',
        'nature familière',
        'câlins imaginaires',
      ],
    ),
    StoryUniverse.adventure: StoryUniverseMeta(
      id: StoryUniverse.adventure,
      displayName: 'Aventure',
      parentDescription:
          'Petits défis sans stress : cartes au trésor, escales et découvertes calmes.',
      emoji: '🧭',
      accentColor: Color(0xFFC9986B),
      subUniverses: [
        'Carte au trésor en papier croquant',
        'Bateau feuille sur un ruisseau plat',
        'Lanterne pour traverser un couloir doux',
        'Carte postale venue d’un pays imaginaire',
        'Sac à dos léger comme une plume',
      ],
      narrativeTags: [
        'exploration douce',
        'curiosité sans danger',
        'pas pressés',
        'découverte chaleureuse',
        'retour toujours au foyer',
      ],
    ),
    StoryUniverse.enchantedNature: StoryUniverseMeta(
      id: StoryUniverse.enchantedNature,
      displayName: 'Nature enchantée',
      parentDescription:
          'Forêts lumineuses, lucioles et mousse — tout est doux et accueillant.',
      emoji: '🌿',
      accentColor: Color(0xFF6B8F71),
      subUniverses: [
        'Sous-bois lumineux, mousses douces et lucioles',
        'Clairière baignée de lait de lune',
        'Champignons comme petites lampes',
        'Ruisseau qui murmure une berceuse',
        'Feuilles qui se balancent comme des berceaux',
      ],
      narrativeTags: [
        'forêt bienveillante',
        'lumière tamisée',
        'odeurs de mousse et miel',
        'silence réconfortant',
        'végétation protectrice',
      ],
    ),
    StoryUniverse.ocean: StoryUniverseMeta(
      id: StoryUniverse.ocean,
      displayName: 'Océan',
      parentDescription:
          'Eau calme, coquillages et reflets de lune — jamais de tempête effrayante.',
      emoji: '🌙',
      accentColor: Color(0xFF6A9FB8),
      subUniverses: [
        'Baie calme, marée basse et reflets de lune',
        'Plage de sable tiède sous les pieds',
        'Coquillage qui écoute les secrets du soir',
        'Dauphin qui glisse sans un bruit',
        'Vague qui recule comme une caresse',
      ],
      narrativeTags: [
        'eau apaisante',
        'horizon rose',
        'respiration large',
        'bercement marin',
        'crépitement doux du sable',
      ],
    ),
    StoryUniverse.space: StoryUniverseMeta(
      id: StoryUniverse.space,
      displayName: 'Espace',
      parentDescription:
          'Étoiles patientes, constellations douces — loin de tout danger ou vitesse.',
      emoji: '🌟',
      accentColor: Color(0xFF7B7299),
      subUniverses: [
        'Nuit tiède et constellations qui respirent',
        'Station spatiale en peluche',
        'Comète qui trace un trait de lumière douce',
        'Lune berceuse et son panier d’argent',
        'Astronaute qui flotte comme dans un rêve',
      ],
      narrativeTags: [
        'cosmos feutré',
        'infini rassurant',
        'lenteur céleste',
        'lueur tamisée',
        'sommeil stellaire',
      ],
    ),
    StoryUniverse.dinosaurs: StoryUniverseMeta(
      id: StoryUniverse.dinosaurs,
      displayName: 'Dinosaures',
      parentDescription:
          'Dinos gentils et un peu maladroits — herbivores, câlins, jamais effrayants.',
      emoji: '🦕',
      accentColor: Color(0xFF9FA86D),
      subUniverses: [
        'Brontosaure au cou couverture',
        'Tricératops qui range ses jouets',
        'Œuf qui roule doucement dans la mousse',
        'Volcan endormi sous un chapeau de nuage',
        'Forêt de fougères hautes comme des câlins',
      ],
      narrativeTags: [
        'dinosaures attendrissants',
        'pas de chasse ni de cris',
        'pas de mâchoires effrayantes',
        'gigantisme doux',
        'passé en berceuse',
      ],
    ),
    StoryUniverse.everydayMagic: StoryUniverseMeta(
      id: StoryUniverse.everydayMagic,
      displayName: 'Monde magique du quotidien',
      parentDescription:
          'La maison, l’école ou le quartier… avec une pincée de magie bienveillante.',
      emoji: '🏠',
      accentColor: Color(0xFFD4A574),
      subUniverses: [
        'Ruelles douces, lanternes et volets chaleureux',
        'Cuisine qui sent le chocolat tiède',
        'Chambre où les ombres deviennent des amis',
        'Bus imaginaire qui ne prend jamais de retard',
        'Parc sous la rosée du matin',
      ],
      narrativeTags: [
        'quotidien enchanté',
        'réconfort familier',
        'petites merveilles cachées',
        'rituel du soir',
        'présence rassurante des proches',
      ],
    ),
  };

  static StoryUniverseMeta metaOf(StoryUniverse u) => all[u]!;

  /// Anciennes valeurs Firestore → nouvel univers.
  static StoryUniverse parseWire(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return StoryUniverse.magicAndFairy;
    }
    final key = raw.trim();
    const legacy = <String, StoryUniverse>{
      'forest': StoryUniverse.enchantedNature,
      'ocean': StoryUniverse.ocean,
      'skyAndStars': StoryUniverse.space,
      'smallVillage': StoryUniverse.everydayMagic,
      'imaginaryKingdom': StoryUniverse.magicAndFairy,
    };
    final mapped = legacy[key];
    if (mapped != null) return mapped;
    return StoryUniverse.values.firstWhere(
      (e) => e.name == key,
      orElse: () => StoryUniverse.magicAndFairy,
    );
  }
}

extension StoryUniverseX on StoryUniverse {
  String get wireValue => name;

  StoryUniverseMeta get meta => StoryUniverseCatalog.metaOf(this);

  String get displayName => meta.displayName;

  String get parentDescription => meta.parentDescription;

  String get emoji => meta.emoji;

  Color get accentColor => meta.accentColor;

  List<String> get subUniverses => meta.subUniverses;

  List<String> get narrativeTags => meta.narrativeTags;

  String get promptBlock => meta.promptBlock;

  static StoryUniverse parse(String? raw) => StoryUniverseCatalog.parseWire(raw);
}
