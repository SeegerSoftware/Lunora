enum StoryFormat {
  /// Histoire complète et indépendante chaque jour.
  dailyStandalone,

  /// Histoire découpée en chapitres sur plusieurs jours.
  serializedChapters,
}

extension StoryFormatFirestore on StoryFormat {
  String get wireValue => name;

  static StoryFormat parse(String? raw) {
    return StoryFormat.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => StoryFormat.dailyStandalone,
    );
  }
}
