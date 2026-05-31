import 'story_universe.dart';

/// Univers simples affichés dans le profil enfant.
enum ProfileStoryUniverse {
  animals,
  gentleMagic,
  adventure,
  nature,
  everydayLife,
  emotionsConfidence,
  dinosaurs,
  space,
}

extension ProfileStoryUniverseX on ProfileStoryUniverse {
  String get wireValue => name;

  String get displayLabel => switch (this) {
    ProfileStoryUniverse.animals => 'Animaux',
    ProfileStoryUniverse.gentleMagic => 'Magie douce',
    ProfileStoryUniverse.adventure => 'Aventure',
    ProfileStoryUniverse.nature => 'Nature',
    ProfileStoryUniverse.everydayLife => 'Famille & quotidien',
    ProfileStoryUniverse.emotionsConfidence => 'Émotions & confiance',
    ProfileStoryUniverse.dinosaurs => 'Dinosaures',
    ProfileStoryUniverse.space => 'Espace',
  };

  StoryUniverse get primaryStoryUniverse => switch (this) {
    ProfileStoryUniverse.animals => StoryUniverse.animals,
    ProfileStoryUniverse.gentleMagic => StoryUniverse.magicAndFairy,
    ProfileStoryUniverse.adventure => StoryUniverse.adventure,
    ProfileStoryUniverse.nature => StoryUniverse.enchantedNature,
    ProfileStoryUniverse.everydayLife => StoryUniverse.everydayMagic,
    ProfileStoryUniverse.emotionsConfidence => StoryUniverse.everydayMagic,
    ProfileStoryUniverse.dinosaurs => StoryUniverse.dinosaurs,
    ProfileStoryUniverse.space => StoryUniverse.space,
  };
}

abstract final class ProfileStoryUniverseMapper {
  static const int maxSelections = 3;

  static List<ProfileStoryUniverse> parseStored(
    List<String> raw, {
    required List<String> legacyThemes,
    required StoryUniverse legacyPrimaryUniverse,
  }) {
    final parsed = <ProfileStoryUniverse>[];
    for (final value in raw) {
      final direct = ProfileStoryUniverse.values.where(
        (option) => option.wireValue == value.trim(),
      );
      if (direct.isNotEmpty) _addUnique(parsed, direct.first);
    }
    if (parsed.isNotEmpty) return parsed.take(maxSelections).toList();

    for (final theme in legacyThemes) {
      final mapped = fromLegacyLabel(theme);
      if (mapped != null) _addUnique(parsed, mapped);
    }
    _addUnique(parsed, fromLegacyStoryUniverse(legacyPrimaryUniverse));
    return parsed.take(maxSelections).toList();
  }

  static ProfileStoryUniverse? fromLegacyLabel(String raw) {
    final key = _normalize(raw);
    if (_containsAny(key, const ['chat', 'chien', 'animal', 'animaux'])) {
      return ProfileStoryUniverse.animals;
    }
    if (_containsAny(key, const [
      'fee',
      'fees',
      'licorne',
      'conte de fees',
      'magie',
      'magique',
    ])) {
      return ProfileStoryUniverse.gentleMagic;
    }
    if (_containsAny(key, const [
      'foret',
      'jardin',
      'montagne',
      'printemps',
      'hiver',
      'nature',
    ])) {
      return ProfileStoryUniverse.nature;
    }
    if (_containsAny(key, const ['famille', 'ecole', 'maison', 'quotidien'])) {
      return ProfileStoryUniverse.everydayLife;
    }
    if (_containsAny(key, const ['peur', 'confiance', 'timidite', 'emotion'])) {
      return ProfileStoryUniverse.emotionsConfidence;
    }
    if (key.contains('dinosaure')) return ProfileStoryUniverse.dinosaurs;
    if (key.contains('espace')) return ProfileStoryUniverse.space;
    if (_containsAny(key, const ['aventure', 'voyage', 'exploration'])) {
      return ProfileStoryUniverse.adventure;
    }
    return null;
  }

  static ProfileStoryUniverse fromLegacyStoryUniverse(StoryUniverse universe) {
    return switch (universe) {
      StoryUniverse.magicAndFairy => ProfileStoryUniverse.gentleMagic,
      StoryUniverse.animals => ProfileStoryUniverse.animals,
      StoryUniverse.adventure => ProfileStoryUniverse.adventure,
      StoryUniverse.enchantedNature ||
      StoryUniverse.ocean => ProfileStoryUniverse.nature,
      StoryUniverse.space => ProfileStoryUniverse.space,
      StoryUniverse.dinosaurs => ProfileStoryUniverse.dinosaurs,
      StoryUniverse.everydayMagic => ProfileStoryUniverse.everydayLife,
    };
  }

  static String _normalize(String value) {
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
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _containsAny(String value, List<String> candidates) {
    return candidates.any(value.contains);
  }

  static void _addUnique(
    List<ProfileStoryUniverse> values,
    ProfileStoryUniverse value,
  ) {
    if (!values.contains(value)) values.add(value);
  }
}
