/// Calcule l’âge en années entières à partir du mois et de l’année de naissance.
/// La date d’anniversaire est approximée au 1er du mois (seules le mois et l’année sont connus).
abstract final class AgeCalculator {
  static int ageInYears({required int birthMonth, required int birthYear}) {
    final now = DateTime.now();
    if (birthYear > now.year ||
        (birthYear == now.year && birthMonth > now.month)) {
      return 0;
    }

    var years = now.year - birthYear;
    final birthdayThisYear = DateTime(now.year, birthMonth, 1);
    if (now.isBefore(birthdayThisYear)) {
      years -= 1;
    }
    return years.clamp(0, 18);
  }
}
