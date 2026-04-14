import '../../services/mock/mock_data.dart';
import '../../shared/models/child_profile.dart';
import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/enums/universe_type.dart';

/// Règles métier + normalisation profil enfant (MVP mock).
abstract final class ChildProfileRules {
  static ChildProfile normalize(ChildProfile input) {
    if (input.storyFormat == StoryFormat.dailyStandalone) {
      return input.copyWith(seriesDurationDays: 0);
    }
    return input.copyWith(
      seriesDurationDays: _coerceSeriesDurationDays(input.seriesDurationDays),
    );
  }

  static int _coerceSeriesDurationDays(int raw) {
    if (MockData.seriesDurationDaysAllowed.contains(raw)) return raw;
    return 7;
  }

  /// À appeler sur un profil **déjà normalisé**.
  static String? validate(ChildProfile profile) {
    if (profile.firstName.trim().isEmpty) {
      return 'Le prénom est obligatoire';
    }
    if (profile.birthMonth < 1 || profile.birthMonth > 12) {
      return 'Mois de naissance invalide';
    }
    final y = profile.birthYear;
    final minY = MockData.minBirthYear();
    final maxY = MockData.maxBirthYear();
    if (y > maxY) return 'L’année de naissance ne peut pas être dans le futur';
    if (y < minY) return 'Année de naissance peu réaliste pour l’app';

    if (!MockData.storyLengthMinutesAllowed.contains(
      profile.storyLengthMinutes,
    )) {
      return 'Durée d’histoire invalide';
    }

    if (profile.storyFormat == StoryFormat.serializedChapters) {
      if (!MockData.seriesDurationDaysAllowed.contains(
        profile.seriesDurationDays,
      )) {
        return 'Durée de série obligatoire (7, 14, 21 ou 28 jours)';
      }
    } else if (profile.seriesDurationDays != 0) {
      return 'Incohérence : durée de série sans format sérialisé';
    }

    return null;
  }

  static String? validateBirthMonth(int month) {
    if (month < 1 || month > 12) return 'Mois entre 1 et 12';
    return null;
  }

  static String? validateBirthYear(int year) {
    if (year > MockData.maxBirthYear()) {
      return 'L’année ne peut pas être dans le futur';
    }
    if (year < MockData.minBirthYear()) {
      return 'Année peu réaliste';
    }
    return null;
  }

  static String? validateStoryMinutes(int minutes) {
    if (!MockData.storyLengthMinutesAllowed.contains(minutes)) {
      return 'Choisissez une durée d’histoire (5, 10 ou 15 min)';
    }
    return null;
  }

  static String? validateSeriesDaysForFormat(
    StoryFormat format,
    int seriesDays,
  ) {
    if (format == StoryFormat.serializedChapters) {
      if (!MockData.seriesDurationDaysAllowed.contains(seriesDays)) {
        return 'Choisissez une durée de série';
      }
    }
    return null;
  }

  static UniverseType defaultUniverseType() => UniverseType.skyAndStars;

  static StoryTone defaultTone() => StoryTone.reassuring;
}
