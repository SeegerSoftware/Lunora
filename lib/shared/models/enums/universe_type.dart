enum UniverseType { forest, ocean, skyAndStars, smallVillage, imaginaryKingdom }

extension UniverseTypeX on UniverseType {
  String get wireValue => name;

  String get displayLabel => switch (this) {
    UniverseType.forest => 'Forêt douce',
    UniverseType.ocean => 'Océan calme',
    UniverseType.skyAndStars => 'Ciel étoilé',
    UniverseType.smallVillage => 'Petit village',
    UniverseType.imaginaryKingdom => 'Royaume imaginaire',
  };

  static UniverseType parse(String? raw) {
    return UniverseType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => UniverseType.skyAndStars,
    );
  }
}
