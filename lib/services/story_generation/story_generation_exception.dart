/// Erreur métier de génération d’histoire (affichable à l’utilisateur).
class StoryGenerationException implements Exception {
  StoryGenerationException(this.message);

  final String message;

  @override
  String toString() => message;
}
