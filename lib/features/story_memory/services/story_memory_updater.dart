import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/story.dart';
import '../domain/story_memory_snapshot.dart';
import '../domain/story_world.dart';
import '../data/story_memory_repository.dart';

/// Après sauvegarde d’une histoire : snapshot + mise à jour du monde.
abstract final class StoryMemoryUpdater {
  static const _emotionBeats = <String>[
    'Un moment de fierté douce et partagée.',
    'Un élan de courage calme, sans précipitation.',
    'Un réconfort chaleureux avant le silence.',
    'Une amitié simple qui rassure le cœur.',
    'Une petite victoire intérieure, à la mesure de l’enfant.',
  ];

  static Future<void> afterStorySaved({
    required StoryMemoryRepository repository,
    required Story story,
    required ChildProfile child,
    required StoryWorld worldBefore,
  }) async {
    final snap = _buildSnapshot(story: story, child: child, world: worldBefore);
    await repository.saveSnapshot(snap);
    final updated = _mergeWorld(worldBefore, snap, story, child);
    await repository.updateWorld(updated);
  }

  static StoryMemorySnapshot _buildSnapshot({
    required Story story,
    required ChildProfile child,
    required StoryWorld world,
  }) {
    final summary = story.summary.trim();
    final short = summary.length > 320 ? '${summary.substring(0, 320)}…' : summary;
    final h = Object.hash(story.id, story.dateKey).abs();
    final emotion = _emotionBeats[h % _emotionBeats.length];
    final lesson = child.valuesToTeach.isNotEmpty
        ? child.valuesToTeach.first.trim()
        : 'Douceur et confiance pour la nuit';
    final places = world.recurringPlaces.isEmpty
        ? <String>[]
        : [
            world.recurringPlaces[h % world.recurringPlaces.length],
            if (world.recurringPlaces.length > 1)
              world.recurringPlaces[(h + 1) % world.recurringPlaces.length],
          ];
    final name = child.firstName.trim().isEmpty ? 'l’enfant' : child.firstName.trim();
    final chars = <String>[
      name,
      if (world.mainCompanion.trim().isNotEmpty) world.mainCompanion,
    ];

    final stateAfter =
        'Après « ${story.title.trim()} » ($name) : ${short.isNotEmpty ? short : "le calme revient progressivement."}';

    return StoryMemorySnapshot(
      id: story.id,
      childId: child.id,
      userId: story.userId,
      storyId: story.id,
      seriesId: story.seriesId,
      dateKey: story.dateKey,
      summaryShort: short.isNotEmpty ? short : story.title,
      usedThemes: [story.theme.trim()].where((e) => e.isNotEmpty).toList(),
      usedPlaces: places,
      usedCharacters: chars,
      emotionBeat: emotion,
      lesson: lesson,
      stateAfterStory: stateAfter,
      createdAt: DateTime.now(),
    );
  }

  static StoryWorld _mergeWorld(
    StoryWorld world,
    StoryMemorySnapshot snap,
    Story story,
    ChildProfile child,
  ) {
    final merged = <String>{
      ...world.recentlyUsedElements,
      ...snap.usedThemes,
      ...snap.usedPlaces,
      ...snap.usedCharacters,
    };
    var list = merged.toList();
    if (list.length > 18) {
      list = list.sublist(list.length - 18);
    }

    final arc = child.storyFormat == StoryFormat.serializedChapters
        ? 'Série · chapitre ${story.chapterNumber} / ${story.totalChapters}'
        : world.currentArc;

    return world.copyWith(
      currentState: snap.stateAfterStory,
      currentArc: arc,
      recentlyUsedElements: list,
      updatedAt: DateTime.now(),
    );
  }
}
