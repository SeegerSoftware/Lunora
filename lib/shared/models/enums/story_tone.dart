enum StoryTone { reassuring, gentleAdventure, poetic, playfulSoft }

extension StoryToneX on StoryTone {
  String get wireValue => name;

  String get displayLabel => switch (this) {
    StoryTone.reassuring => 'Rassurant',
    StoryTone.gentleAdventure => 'Aventurier',
    StoryTone.poetic => 'Poétique',
    StoryTone.playfulSoft => 'Drôle',
  };

  static StoryTone parse(String? raw) {
    return StoryTone.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => StoryTone.reassuring,
    );
  }
}
