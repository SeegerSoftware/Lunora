import '../../../core/utils/date_key_utils.dart';
import '../../story_memory/data/story_memory_repository.dart';
import '../../story_memory/services/story_memory_builder.dart';
import '../../story_memory/services/story_memory_updater.dart';
import '../../../services/mock/lunora_mock_store.dart';
import '../../../services/story_generation/models/story_generation_request.dart';
import '../../../services/story_generation/series_narrative_seed.dart';
import '../../../services/story_generation/story_generation_service.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_model.dart';
import 'story_repository.dart';

class MockStoryRepository implements StoryRepository {
  MockStoryRepository({
    required LunoraMockStore store,
    required StoryGenerationService generationService,
    required StoryMemoryRepository memoryRepository,
  }) : _store = store,
       _generationService = generationService,
       _memoryRepository = memoryRepository;

  final LunoraMockStore _store;
  final StoryGenerationService _generationService;
  final StoryMemoryRepository _memoryRepository;

  @override
  Future<void> reset() async {
    _store.clearStories();
  }

  @override
  Future<Story?> findById(String storyId) async {
    return _store.storyById(storyId);
  }

  @override
  Future<List<Story>> historyForUser(String userId) async {
    final list = _store.storiesForUser(userId);
    list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
    return list;
  }

  @override
  Future<Story> ensureTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    final todayKey = DateKeyUtils.todayKey();
    final cached = _store.storyFor(child.id, todayKey);
    if (cached != null) return cached;

    final isSerialized = child.storyFormat == StoryFormat.serializedChapters;
    final totalChapters = isSerialized ? child.seriesDurationDays : 1;

    late final int chapterIndex;
    late final String? seriesId;

    if (!isSerialized) {
      chapterIndex = 1;
      seriesId = null;
    } else {
      seriesId = 'series_${child.id}';
      final anchorKey = _store.getOrCreateSeriesAnchorDateKey(
        child.id,
        todayKey,
      );
      final anchorDate = DateKeyUtils.parseDateKey(anchorKey);
      final todayDate = DateKeyUtils.parseDateKey(todayKey);
      final dayOffset = DateKeyUtils.calendarDaysBetween(anchorDate, todayDate);
      chapterIndex = (dayOffset + 1).clamp(1, totalChapters);
    }

    final storyWorld = await _memoryRepository.getOrCreateWorld(
      user: user,
      child: child,
    );
    final snapshots = await _memoryRepository.getRecentSnapshots(
      child.id,
      limit: 3,
    );
    final memoryContext = StoryMemoryBuilder.build(
      storyWorld: storyWorld,
      recentSnapshots: snapshots,
      child: child,
      chapterIndex: chapterIndex,
      totalChapters: totalChapters,
    );

    String? continuity;
    if (isSerialized && seriesId != null && chapterIndex > 1) {
      final prev = _store
          .storiesForUser(user.id)
          .where(
            (s) => s.seriesId == seriesId && s.chapterNumber < chapterIndex,
          )
          .toList()
        ..sort((a, b) {
          final c = a.chapterNumber.compareTo(b.chapterNumber);
          if (c != 0) return c;
          return a.dateKey.compareTo(b.dateKey);
        });
      if (prev.isNotEmpty) {
        continuity = SeriesNarrativeSeed.structuredContinuity(
          child: child,
          previousChaptersSorted: prev,
          seriesGlobalObjective: storyWorld.coreGoal,
        );
      }
    }

    final request = StoryGenerationRequest(
      user: user,
      child: child,
      dateKey: todayKey,
      chapterIndex: chapterIndex,
      totalChapters: totalChapters,
      seriesId: seriesId,
      continuityContext: continuity,
      seriesFilRougeBlock: null,
      memoryContext: memoryContext,
    );

    final generated = await _generationService.generate(request);

    final storyId = 'mock_${child.id}_$todayKey';
    final story = Story(
      id: storyId,
      childId: child.id,
      userId: user.id,
      dateKey: todayKey,
      title: generated.title,
      content: generated.content,
      summary: generated.summary,
      theme: generated.themeLabel,
      tone: generated.tone,
      estimatedReadingMinutes: generated.estimatedReadingMinutes,
      format: generated.format,
      chapterNumber: chapterIndex,
      totalChapters: totalChapters,
      seriesId: generated.seriesId ?? seriesId,
      createdAt: DateTime.now(),
    );

    _store.putStory(story);

    await StoryMemoryUpdater.afterStorySaved(
      repository: _memoryRepository,
      story: story,
      child: child,
      worldBefore: storyWorld,
    );

    return story;
  }

  @override
  Future<Story> adminRegenerateTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    final todayKey = DateKeyUtils.todayKey();
    final storyId = 'mock_${child.id}_$todayKey';
    _store.removeStoryForDate(child.id, todayKey);
    _store.removeMemorySnapshotForStory(storyId);
    return ensureTodayStory(user: user, child: child);
  }
}
