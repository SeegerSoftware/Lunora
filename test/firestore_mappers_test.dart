import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elunai_v00/services/firebase/firestore_mappers.dart';
import 'package:elunai_v00/shared/models/child_profile.dart';
import 'package:elunai_v00/shared/models/enums/story_format.dart';
import 'package:elunai_v00/shared/models/enums/story_tone.dart';
import 'package:elunai_v00/shared/models/profile_story_preferences.dart';
import 'package:elunai_v00/shared/models/story_universe.dart';

void main() {
  test('childProfileWrite converts dates to Firestore timestamps', () {
    final now = DateTime(2026, 1, 2, 3, 4);
    final profile = ChildProfile(
      id: 'child-1',
      userId: 'user-1',
      firstName: 'Lina',
      birthMonth: 6,
      birthYear: 2019,
      preferredThemes: const ['océan'],
      avoidThemes: const [],
      personalityTraits: const ['calme'],
      fearsToAddress: const [],
      valuesToTeach: const [],
      storyUniverse: StoryUniverse.ocean,
      preferredTone: StoryTone.poetic,
      storyFormat: StoryFormat.serializedChapters,
      seriesDurationDays: 7,
      storyLengthMinutes: 10,
      storyUniverses: const [
        ProfileStoryUniverse.nature,
        ProfileStoryUniverse.animals,
      ],
      createdAt: now,
      updatedAt: now,
    );

    final map = FirestoreMappers.childProfileWrite(profile);

    expect(map['createdAt'], isA<Timestamp>());
    expect(map['updatedAt'], isA<Timestamp>());
    expect(map['userId'], 'user-1');
    expect(map['universeType'], StoryUniverse.ocean.wireValue);
    expect(map['storyUniverses'], ['nature', 'animals']);
  });

  test('legacy child profile themes migrate to simplified universes', () {
    final profile = ChildProfile.fromMap({
      'id': 'child-legacy',
      'userId': 'user-1',
      'firstName': 'Lina',
      'birthMonth': 6,
      'birthYear': 2019,
      'preferredThemes': ['forêt', 'chat', 'peur du noir', 'espace'],
      'universeType': 'forest',
      'createdAt': DateTime(2026),
      'updatedAt': DateTime(2026),
    });

    expect(profile.storyUniverses, [
      ProfileStoryUniverse.nature,
      ProfileStoryUniverse.animals,
      ProfileStoryUniverse.emotionsConfidence,
    ]);
  });
}
