/// Constantes partagées par les mocks (auth, profil, histoires).
abstract final class MockData {
  static const int minPasswordLength = 6;

  static const Set<int> storyLengthMinutesAllowed = {5, 10, 15};
  static const Set<int> seriesDurationDaysAllowed = {3, 5, 7, 14};

  /// Année de naissance minimum (enfant au plus ~17 ans).
  static int minBirthYear() => DateTime.now().year - 17;

  /// Année de naissance maximum (pas dans le futur).
  static int maxBirthYear() => DateTime.now().year;
}
