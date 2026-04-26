import '../constants/profile_limits.dart';
import '../../shared/models/child_profile.dart';
import 'story_profile_moderation.dart';
import '../../shared/models/enums/story_format.dart';
import '../../shared/models/enums/story_tone.dart';
import '../../shared/models/story_universe.dart';

/// Règles métier + normalisation profil enfant.
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
    if (ProfileLimits.seriesDurationDaysAllowed.contains(raw)) return raw;
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
    final minY = ProfileLimits.minBirthYear();
    final maxY = ProfileLimits.maxBirthYear();
    if (y > maxY) return 'L’année de naissance ne peut pas être dans le futur';
    if (y < minY) return 'Année de naissance peu réaliste pour l’app';

    if (!ProfileLimits.storyLengthMinutesAllowed.contains(
      profile.storyLengthMinutes,
    )) {
      return 'Durée d’histoire invalide';
    }

    if (profile.storyFormat == StoryFormat.serializedChapters) {
      if (!ProfileLimits.seriesDurationDaysAllowed.contains(
        profile.seriesDurationDays,
      )) {
        return 'Durée de série obligatoire (7 jours)';
      }
    } else if (profile.seriesDurationDays != 0) {
      return 'Incohérence : durée de série sans format sérialisé';
    }

    final moderation = StoryProfileModeration.validateChildProfile(profile);
    if (moderation != null) return moderation;

    return null;
  }

  static String? validateBirthMonth(int month) {
    if (month < 1 || month > 12) return 'Mois entre 1 et 12';
    return null;
  }

  static String? validateBirthYear(int year) {
    if (year > ProfileLimits.maxBirthYear()) {
      return 'L’année ne peut pas être dans le futur';
    }
    if (year < ProfileLimits.minBirthYear()) {
      return 'Année peu réaliste';
    }
    return null;
  }

  static String? validateStoryMinutes(int minutes) {
    if (!ProfileLimits.storyLengthMinutesAllowed.contains(minutes)) {
      return 'Durée d’histoire invalide (10 min attendu)';
    }
    return null;
  }

  static String? validateSeriesDaysForFormat(
    StoryFormat format,
    int seriesDays,
  ) {
    if (format == StoryFormat.serializedChapters) {
      if (!ProfileLimits.seriesDurationDaysAllowed.contains(seriesDays)) {
        return 'Choisissez une durée de série';
      }
    }
    return null;
  }

  static StoryUniverse defaultStoryUniverse() => StoryUniverse.magicAndFairy;

  static StoryTone defaultTone() => StoryTone.reassuring;
}
