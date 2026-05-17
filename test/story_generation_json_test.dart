import 'package:flutter_test/flutter_test.dart';
import 'package:lunora_v00/services/story_generation/models/story_generation_request.dart';
import 'package:lunora_v00/services/story_generation/story_generation_json.dart';
import 'package:lunora_v00/shared/models/child_profile.dart';
import 'package:lunora_v00/shared/models/enums/story_format.dart';
import 'package:lunora_v00/shared/models/enums/story_tone.dart';
import 'package:lunora_v00/shared/models/enums/subscription_status.dart';
import 'package:lunora_v00/shared/models/story_universe.dart';
import 'package:lunora_v00/shared/models/user_model.dart';

void main() {
  test('extractObject accepts fenced JSON with surrounding text', () {
    final object = StoryGenerationJsonParser.extractObject('''
Voici la réponse:
```json
{"title":"Lumière","content":"Texte","summary":"Résumé"}
```
''');

    expect(object['title'], 'Lumière');
  });

  test('normalize uses request as source of truth for chapter metadata', () {
    final request = StoryGenerationRequest(
      user: UserModel(
        id: 'user-1',
        email: 'parent@example.com',
        createdAt: DateTime(2026, 1, 1),
        subscriptionStatus: SubscriptionStatus.none,
      ),
      child: _profile(),
      dateKey: '2026-05-17',
      chapterIndex: 3,
      totalChapters: 7,
      seriesId: 'series-child-1',
    );
    final parsed = StoryGenerationJsonParser.parseMap({
      'title': 'Le jardin calme',
      'content': List.filled(650, 'douce').join(' '),
      'summary': 'Une histoire calme.',
      'theme': 'Jardin',
      'tone': 'poetic',
      'estimatedReadingMinutes': 42,
      'chapterNumber': 99,
      'totalChapters': 99,
    });

    final result = StoryGenerationResultNormalizer.normalize(
      parsed: parsed,
      request: request,
    );

    expect(result.chapterNumber, 3);
    expect(result.totalChapters, 7);
    expect(result.seriesId, 'series-child-1');
    expect(result.estimatedReadingMinutes, 10);
  });
}

ChildProfile _profile() {
  final now = DateTime(2026, 1, 1);
  return ChildProfile(
    id: 'child-1',
    userId: 'user-1',
    firstName: 'Lina',
    birthMonth: 6,
    birthYear: 2019,
    preferredThemes: const ['jardin'],
    avoidThemes: const [],
    personalityTraits: const ['curieuse'],
    fearsToAddress: const [],
    valuesToTeach: const [],
    storyUniverse: StoryUniverse.enchantedNature,
    preferredTone: StoryTone.reassuring,
    storyFormat: StoryFormat.serializedChapters,
    seriesDurationDays: 7,
    storyLengthMinutes: 10,
    createdAt: now,
    updatedAt: now,
  );
}
