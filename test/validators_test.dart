import 'package:flutter_test/flutter_test.dart';
import 'package:lunora_v00/core/validation/auth_validators.dart';
import 'package:lunora_v00/core/validation/child_profile_rules.dart';
import 'package:lunora_v00/shared/models/child_profile.dart';
import 'package:lunora_v00/shared/models/enums/story_format.dart';
import 'package:lunora_v00/shared/models/enums/story_tone.dart';
import 'package:lunora_v00/shared/models/story_universe.dart';

void main() {
  group('AuthValidators', () {
    test('rejects invalid email', () {
      expect(AuthValidators.emailError('bad-email'), isNotNull);
      expect(AuthValidators.emailError('parent@example.com'), isNull);
    });

    test('rejects short password', () {
      expect(AuthValidators.passwordError('123'), isNotNull);
      expect(AuthValidators.passwordError('12345678'), isNull);
    });
  });

  group('ChildProfileRules', () {
    test('normalizes standalone series duration to zero', () {
      final profile = _profile(
        storyFormat: StoryFormat.dailyStandalone,
        seriesDurationDays: 7,
      );

      final normalized = ChildProfileRules.normalize(profile);

      expect(normalized.seriesDurationDays, 0);
    });

    test('accepts a valid serialized profile', () {
      final profile = ChildProfileRules.normalize(_profile());

      expect(ChildProfileRules.validate(profile), isNull);
    });

    test('rejects missing first name', () {
      final profile = ChildProfileRules.normalize(_profile(firstName: ''));

      expect(ChildProfileRules.validate(profile), isNotNull);
    });
  });
}

ChildProfile _profile({
  String firstName = 'Lina',
  StoryFormat storyFormat = StoryFormat.serializedChapters,
  int seriesDurationDays = 7,
}) {
  final now = DateTime(2026, 1, 1);
  return ChildProfile(
    id: 'child-1',
    userId: 'user-1',
    firstName: firstName,
    birthMonth: 6,
    birthYear: 2019,
    preferredThemes: const ['forêt'],
    avoidThemes: const [],
    personalityTraits: const ['curieuse'],
    fearsToAddress: const [],
    valuesToTeach: const ['partage'],
    storyUniverse: StoryUniverse.enchantedNature,
    preferredTone: StoryTone.reassuring,
    storyFormat: storyFormat,
    seriesDurationDays: seriesDurationDays,
    storyLengthMinutes: 10,
    createdAt: now,
    updatedAt: now,
  );
}
