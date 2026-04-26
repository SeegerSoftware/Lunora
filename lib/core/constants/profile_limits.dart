/// Limites profil enfant / auth (hors mock, valeurs produit).
abstract final class ProfileLimits {
  static const int minPasswordLength = 6;

  static const Set<int> storyLengthMinutesAllowed = {10};
  static const Set<int> seriesDurationDaysAllowed = {7};

  static int minBirthYear() => DateTime.now().year - 17;

  static int maxBirthYear() => DateTime.now().year;
}
