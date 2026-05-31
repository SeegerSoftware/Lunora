import 'package:flutter_test/flutter_test.dart';
import 'package:elunai_v00/features/stories/data/series_state_reducer.dart';
import 'package:elunai_v00/shared/models/child_profile.dart';
import 'package:elunai_v00/shared/models/enums/story_format.dart';
import 'package:elunai_v00/shared/models/enums/story_tone.dart';
import 'package:elunai_v00/shared/models/profile_story_preferences.dart';
import 'package:elunai_v00/shared/models/series_state.dart';
import 'package:elunai_v00/shared/models/story_universe.dart';

void main() {
  test('advances through seven chapters and completes the weekly series', () {
    var state = _state();

    for (var chapter = 1; chapter <= 7; chapter++) {
      state = SeriesStateReducer.advance(
        state: state,
        chapterIndex: chapter,
        fallbackSummary: 'summary $chapter',
        continuityUpdate: _update(chapter),
        now: DateTime(2026, 5, chapter),
      );
    }

    expect(state.currentChapterIndex, 7);
    expect(state.status, 'completed');
    expect(state.completedAt, DateTime(2026, 5, 7));
    expect(state.chapterSummaries, hasLength(7));
    expect(
      state.continuitySummary,
      'summary 2 | summary 3 | summary 4 | summary 5 | summary 6 | summary 7',
    );
    expect(state.openLoops, isEmpty);
  });

  test('rewinds the current chapter before admin regeneration', () {
    var state = _state();
    for (var chapter = 1; chapter <= 3; chapter++) {
      state = SeriesStateReducer.advance(
        state: state,
        chapterIndex: chapter,
        fallbackSummary: 'summary $chapter',
        continuityUpdate: _update(chapter),
        now: DateTime(2026, 5, chapter),
      );
    }

    final rewound = SeriesStateReducer.rewindCurrentChapter(
      state: state,
      chapterIndex: 3,
      now: DateTime(2026, 5, 3, 12),
    );

    expect(rewound.currentChapterIndex, 2);
    expect(rewound.status, 'active');
    expect(rewound.chapterSummaries, ['summary 1', 'summary 2']);
    expect(rewound.lastChapterSummary, 'summary 2');
    expect(rewound.openLoops, ['loop 2']);
  });

  test('series state map keeps the renewal-specific series id', () {
    final restored = SeriesState.fromMap(_state().toMap());

    expect(restored.seriesId, 'series_child-1_2026-05-01');
  });

  test('series state map keeps the profile snapshot used for generation', () {
    final restored = SeriesState.fromMap(
      _state().copyWith(profileSnapshot: _profile()).toMap(),
    );

    expect(restored.profileSnapshot, _profile());
    expect(restored.profileSnapshot?.preferredThemes, ['forest']);
  });

  test(
    'legacy state keeps existing continuity when the next chapter advances',
    () {
      final legacy = _state().copyWith(
        currentChapterIndex: 2,
        chapterSummaries: const ['legacy 1', 'legacy 2'],
        continuitySummary: 'legacy 1 | legacy 2',
        antiRepetitionMemory: const ['legacy avoid'],
      );

      final advanced = SeriesStateReducer.advance(
        state: legacy,
        chapterIndex: 3,
        fallbackSummary: 'summary 3',
        continuityUpdate: _update(3),
        now: DateTime(2026, 5, 3),
      );

      expect(advanced.chapterSummaries, ['legacy 1', 'legacy 2', 'summary 3']);
      expect(advanced.antiRepetitionMemory, ['legacy avoid']);
    },
  );
}

ChildProfile _profile() {
  final now = DateTime(2026, 5, 1);
  return ChildProfile(
    id: 'child-1',
    userId: 'user-1',
    firstName: 'Lina',
    birthMonth: 6,
    birthYear: 2019,
    preferredThemes: const ['forest'],
    avoidThemes: const [],
    personalityTraits: const ['curious'],
    fearsToAddress: const [],
    valuesToTeach: const [],
    storyUniverse: StoryUniverse.enchantedNature,
    preferredTone: StoryTone.reassuring,
    storyFormat: StoryFormat.serializedChapters,
    seriesDurationDays: 7,
    storyLengthMinutes: 10,
    storyUniverses: const [ProfileStoryUniverse.nature],
    readingDurationMinutes: 10,
    createdAt: now,
    updatedAt: now,
  );
}

ChapterContinuityUpdate _update(int chapter) {
  return ChapterContinuityUpdate(
    chapterSummary: 'summary $chapter',
    importantEvents: const [],
    charactersMet: const [],
    objectsIntroduced: ['object $chapter'],
    resolvedLoops: chapter == 1 ? const [] : ['loop ${chapter - 1}'],
    openLoops: ['loop $chapter'],
    emotionalStep: 'emotion $chapter',
    thingsToRemember: const [],
    thingsToAvoidRepeating: ['avoid $chapter'],
    nextChapterGoal: 'goal ${chapter + 1}',
  );
}

SeriesState _state() {
  final now = DateTime(2026, 5, 1);
  return SeriesState(
    id: 'child-1_user-1',
    seriesId: 'series_child-1_2026-05-01',
    childId: 'child-1',
    userId: 'user-1',
    status: 'active',
    seriesTitle: 'Weekly story',
    seriesFormat: 'serialized',
    currentChapterIndex: 0,
    totalChapters: 7,
    seriesDurationDays: 7,
    universe: 'forest',
    tone: 'reassuring',
    mainCharacters: const ['Lina'],
    secondaryCharacters: const [],
    recurringPlaces: const [],
    storyArc: 'arc',
    emotionalArc: 'emotional arc',
    chapterPlan: [
      for (var chapter = 1; chapter <= 7; chapter++)
        ChapterPlanItem(
          chapterIndex: chapter,
          title: 'chapter $chapter',
          goal: 'goal $chapter',
          emotionalStep: 'emotion $chapter',
          newElement: 'object $chapter',
          openLoop: 'loop $chapter',
        ),
    ],
    continuitySummary: '',
    chapterSummaries: const [],
    openLoops: const [],
    resolvedLoops: const [],
    importantObjects: const [],
    emotionalProgression: const [],
    antiRepetitionMemory: const ['base avoid'],
    antiRepetitionRules: const ['base avoid'],
    chapterContinuityUpdates: const [],
    lastChapterSummary: '',
    nextChapterGoal: 'goal 1',
    createdAt: now,
    updatedAt: now,
  );
}
