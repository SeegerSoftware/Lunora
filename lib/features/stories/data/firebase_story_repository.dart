import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/config/ai_generation_config.dart';
import '../../../core/utils/date_key_utils.dart';
import '../../story_memory/data/story_memory_repository.dart';
import '../../story_memory/services/story_memory_builder.dart';
import '../../story_memory/services/story_memory_updater.dart';
import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_mappers.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../services/story_generation/models/story_generation_request.dart';
import '../../../services/story_generation/series_narrative_seed.dart';
import '../../../services/story_generation/story_generation_service.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_model.dart';
import 'story_repository.dart';

class FirebaseStoryRepository implements StoryRepository {
  FirebaseStoryRepository({
    FirebaseFirestore? firestore,
    required StoryGenerationService generationService,
    required StoryMemoryRepository memoryRepository,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _generationService = generationService,
       _memoryRepository = memoryRepository;

  final FirebaseFirestore _db;
  final StoryGenerationService _generationService;
  final StoryMemoryRepository _memoryRepository;

  @override
  Future<void> reset() async {}

  @override
  Future<Story?> findById(String storyId) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.stories)
          .doc(storyId)
          .get();
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      data['id'] = snap.id;
      return Story.fromMap(data);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<List<Story>> historyForUser(String userId) async {
    try {
      final query = await _db
          .collection(FirestorePaths.stories)
          .where('userId', isEqualTo: userId)
          .get();
      final list = query.docs.map((d) {
        final m = Map<String, dynamic>.from(d.data());
        m['id'] = d.id;
        return Story.fromMap(m);
      }).toList();
      list.sort((a, b) => b.dateKey.compareTo(a.dateKey));
      return list;
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<Story> ensureTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    final todayKey = DateKeyUtils.todayKey();
    final storyId = 'mock_${child.id}_$todayKey';

    try {
      final ref = _db.collection(FirestorePaths.stories).doc(storyId);
      final existing = await ref.get();
      if (existing.exists && existing.data() != null) {
        final m = Map<String, dynamic>.from(existing.data()!);
        m['id'] = existing.id;
        final cached = Story.fromMap(m);
        final shouldRefreshFromAi =
            AiGenerationConfig.canUseRemoteAi &&
            cached.generationSource.startsWith('fallback');
        if (!shouldRefreshFromAi) return cached;
        await ref.delete();
      }

      final isSerialized = child.storyFormat == StoryFormat.serializedChapters;
      final totalChapters = isSerialized ? child.seriesDurationDays : 1;

      late final int chapterIndex;
      late final String? seriesId;

      if (!isSerialized) {
        chapterIndex = 1;
        seriesId = null;
      } else {
        seriesId = 'series_${child.id}';
        final anchorKey = await _getOrCreateSeriesAnchor(
          childId: child.id,
          userId: user.id,
          todayKey: todayKey,
        );
        final anchorDate = DateKeyUtils.parseDateKey(anchorKey);
        final todayDate = DateKeyUtils.parseDateKey(todayKey);
        final dayOffset = DateKeyUtils.calendarDaysBetween(
          anchorDate,
          todayDate,
        );
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
        continuity = await _seriesStructuredContinuity(
          userId: user.id,
          seriesId: seriesId,
          currentChapter: chapterIndex,
          child: child,
          seriesGlobalObjective: storyWorld.coreGoal,
        );
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
        generationSource: generated.generationSource,
        createdAt: DateTime.now(),
      );

      await ref.set(FirestoreMappers.storyWrite(story));

      await StoryMemoryUpdater.afterStorySaved(
        repository: _memoryRepository,
        story: story,
        child: child,
        worldBefore: storyWorld,
      );

      return story;
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<Story> adminRegenerateTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    final todayKey = DateKeyUtils.todayKey();
    final storyId = 'mock_${child.id}_$todayKey';
    try {
      final storyRef = _db.collection(FirestorePaths.stories).doc(storyId);
      final snapRef = _db
          .collection(FirestorePaths.storyMemorySnapshots)
          .doc(storyId);
      final doc = await storyRef.get();
      if (doc.exists) {
        await storyRef.delete();
      }
      final snap = await snapRef.get();
      if (snap.exists) {
        await snapRef.delete();
      }
      return ensureTodayStory(user: user, child: child);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  Future<List<Story>> _priorSeriesStories({
    required String userId,
    required String seriesId,
    required int currentChapter,
  }) async {
    final snap = await _db
        .collection(FirestorePaths.stories)
        .where('seriesId', isEqualTo: seriesId)
        .get();
    final stories = snap.docs
        .map((d) {
          final m = Map<String, dynamic>.from(d.data());
          m['id'] = d.id;
          return Story.fromMap(m);
        })
        .where((s) => s.userId == userId && s.chapterNumber < currentChapter)
        .toList()
      ..sort((a, b) {
        final c = a.chapterNumber.compareTo(b.chapterNumber);
        if (c != 0) return c;
        return a.dateKey.compareTo(b.dateKey);
      });
    return stories;
  }

  Future<String?> _seriesStructuredContinuity({
    required String userId,
    required String seriesId,
    required int currentChapter,
    required ChildProfile child,
    required String seriesGlobalObjective,
  }) async {
    try {
      final stories = await _priorSeriesStories(
        userId: userId,
        seriesId: seriesId,
        currentChapter: currentChapter,
      );
      if (stories.isEmpty) return null;
      return SeriesNarrativeSeed.structuredContinuity(
        child: child,
        previousChaptersSorted: stories,
        seriesGlobalObjective: seriesGlobalObjective,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String> _getOrCreateSeriesAnchor({
    required String childId,
    required String userId,
    required String todayKey,
  }) async {
    final stateRef = _db.collection(FirestorePaths.childSeriesState).doc(childId);
    final snap = await stateRef.get();
    if (snap.exists && snap.data()?['anchorDateKey'] != null) {
      return snap.data()!['anchorDateKey'] as String;
    }
    await stateRef.set({
      'anchorDateKey': todayKey,
      'userId': userId,
    }, SetOptions(merge: true));
    return todayKey;
  }
}
