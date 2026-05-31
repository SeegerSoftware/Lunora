import 'package:flutter_test/flutter_test.dart';
import 'package:elunai_v00/shared/models/achievement.dart';
import 'package:elunai_v00/shared/models/enums/story_format.dart';
import 'package:elunai_v00/shared/models/enums/story_tone.dart';
import 'package:elunai_v00/shared/models/story.dart';

void main() {
  test('legacy story documents receive deferred premium media defaults', () {
    final story = Story.fromMap(_storyMap());

    expect(story.qualityScore, 0);
    expect(story.coverImageStatus, 'pending');
    expect(story.audioStatus, 'unavailable');
  });

  test('premium story metadata round-trips through the map contract', () {
    final story = Story.fromMap({
      ..._storyMap(),
      'qualityScore': 91,
      'qualityDetails': {'structure': 25},
      'qualityWarnings': ['warning'],
      'coverImageUrl': 'https://example.test/cover.jpg',
      'coverImageStatus': 'ready',
      'coverPrompt': 'portrait storybook cover',
      'audioStatus': 'queued',
    });

    expect(story.toMap()['qualityScore'], 91);
    expect(story.toMap()['coverImageStatus'], 'ready');
    expect(story.toMap()['audioStatus'], 'queued');
  });

  test('achievement calculator exposes discreet reading milestones', () {
    final stories = List.generate(
      7,
      (index) => Story.fromMap({..._storyMap(), 'id': 'story-$index'}),
    );

    expect(
      AchievementCalculator.earned(stories).map((item) => item.id),
      containsAll(['first_story', 'stories_7']),
    );
  });
}

Map<String, dynamic> _storyMap() => {
  'id': 'story-1',
  'childId': 'child-1',
  'userId': 'user-1',
  'dateKey': '2026-05-31',
  'title': 'La lumiere',
  'content': 'Une histoire suffisamment longue.',
  'summary': 'Resume',
  'theme': 'Nature',
  'tone': StoryTone.reassuring.wireValue,
  'format': StoryFormat.dailyStandalone.wireValue,
  'estimatedReadingMinutes': 10,
  'chapterNumber': 1,
  'totalChapters': 1,
  'createdAt': DateTime(2026, 5, 31),
};
