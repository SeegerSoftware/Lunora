import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/ai_generation_config.dart';
import '../../../core/utils/date_key_utils.dart';
import '../../story_memory/domain/story_memory_context.dart';
import '../../story_memory/data/story_memory_repository.dart';
import '../../story_memory/services/story_memory_builder.dart';
import '../../story_memory/services/story_memory_updater.dart';
import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_mappers.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../services/story_generation/models/story_generation_request.dart';
import '../../../services/story_generation/story_generation_service.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/series_state.dart';
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
      if (_isPermissionDenied(e)) {
        if (kDebugMode) {
          debugPrint('Story read denied for $storyId, returning null.');
        }
        return null;
      }
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
    final storyId = _todayStoryDocId(
      userId: user.id,
      childId: child.id,
      dateKey: todayKey,
    );

    try {
      final ref = _db.collection(FirestorePaths.stories).doc(storyId);
      DocumentSnapshot<Map<String, dynamic>>? existing;
      try {
        existing = await ref.get();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Story cache read skipped for $storyId: $e');
        }
      }
      final existingSnap = existing;
      if (existingSnap != null && existingSnap.exists && existingSnap.data() != null) {
        final m = Map<String, dynamic>.from(existingSnap.data()!);
        m['id'] = existingSnap.id;
        final cached = Story.fromMap(m);
        final shouldRefreshFromAi =
            AiGenerationConfig.canUseRemoteAi &&
            cached.generationSource.startsWith('fallback');
        if (!shouldRefreshFromAi) return cached;
        try {
          await ref.delete();
        } catch (e) {
          // Anciennes données peuvent être non supprimables selon les règles.
          // On retourne le cache plutôt que bloquer le parent.
          if (kDebugMode) {
            debugPrint('Story refresh skipped (delete denied): $e');
          }
          return cached;
        }
      }

      final isSerialized = child.storyFormat == StoryFormat.serializedChapters;
      final totalChapters = isSerialized ? child.seriesDurationDays : 1;

      late final int chapterIndex;
      late final String? seriesId;
      SeriesState? activeSeriesState;
      SeriesBible? seriesBible;
      ChapterPlanItem? currentChapterPlan;

      if (!isSerialized) {
        chapterIndex = 1;
        seriesId = null;
      } else {
        seriesId = 'series_${child.id}';
        final seriesStateDocId = _seriesStateDocId(
          childId: child.id,
          userId: user.id,
        );
        activeSeriesState = await _loadSeriesState(seriesStateDocId);
        if (activeSeriesState == null ||
            activeSeriesState.status != 'active' ||
            activeSeriesState.currentChapterIndex >=
                activeSeriesState.totalChapters) {
          final bibleRequest = StoryGenerationRequest(
            user: user,
            child: child,
            dateKey: todayKey,
            chapterIndex: 1,
            totalChapters: totalChapters,
            seriesId: seriesId,
          );
          seriesBible = await _generationService.generateSeriesBible(bibleRequest);
          activeSeriesState = await _createSeriesState(
            stateDocId: seriesStateDocId,
            child: child,
            user: user,
            seriesId: seriesId,
            bible: seriesBible,
            totalChapters: totalChapters,
          );
        } else {
          seriesBible = _extractSeriesBible(activeSeriesState);
        }
        chapterIndex = (activeSeriesState.currentChapterIndex + 1).clamp(
          1,
          activeSeriesState.totalChapters,
        );
        currentChapterPlan = _planForChapter(activeSeriesState, chapterIndex);
      }

      final memoryContext = await _safeBuildMemoryContext(
        user: user,
        child: child,
        chapterIndex: chapterIndex,
        totalChapters: totalChapters,
      );

      final request = StoryGenerationRequest(
        user: user,
        child: child,
        dateKey: todayKey,
        chapterIndex: chapterIndex,
        totalChapters: totalChapters,
        seriesId: seriesId,
        continuityContext: activeSeriesState?.continuitySummary,
        seriesFilRougeBlock: null,
        memoryContext: memoryContext,
        seriesBible: seriesBible,
        seriesState: activeSeriesState,
        currentChapterPlan: currentChapterPlan,
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

      if (isSerialized && activeSeriesState != null) {
        await _updateSeriesStateAfterChapter(
          stateDocId: activeSeriesState.id,
          state: activeSeriesState,
          chapterIndex: chapterIndex,
          story: story,
          continuityUpdate: generated.continuityUpdate,
        );
      }

      await _safeUpdateMemoryAfterStorySaved(story: story, child: child, user: user);

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
    final storyId = _todayStoryDocId(
      userId: user.id,
      childId: child.id,
      dateKey: todayKey,
    );
    try {
      final storyRef = _db.collection(FirestorePaths.stories).doc(storyId);
      final snapRef = _db
          .collection(FirestorePaths.storyMemorySnapshots)
          .doc(storyId);
      await _safeDeleteDoc(storyRef);
      await _safeDeleteDoc(snapRef);
      return ensureTodayStory(user: user, child: child);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  Future<void> _safeDeleteDoc(DocumentReference<Map<String, dynamic>> ref) async {
    try {
      final doc = await ref.get();
      if (doc.exists) {
        await ref.delete();
      }
    } catch (e) {
      // Tolérance legacy: certains anciens docs peuvent ne pas passer les règles.
      if (kDebugMode) {
        debugPrint('Safe delete skipped for ${ref.path}: $e');
      }
    }
  }

  String _todayStoryDocId({
    required String userId,
    required String childId,
    required String dateKey,
  }) {
    return 'story_${userId}_${childId}_$dateKey';
  }

  bool _isPermissionDenied(Object error) {
    final raw = error.toString().toLowerCase();
    return raw.contains('permission-denied') ||
        raw.contains('insufficient permissions') ||
        raw.contains('acces refuse');
  }

  String _seriesStateDocId({
    required String childId,
    required String userId,
  }) {
    return '${childId}_$userId';
  }

  Future<SeriesState?> _loadSeriesState(String stateDocId) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.childSeriesState)
          .doc(stateDocId)
          .get();
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      data['id'] = snap.id;
      return SeriesState.fromMap(data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Series state read skipped for $stateDocId: $e');
      }
      return null;
    }
  }

  SeriesBible _extractSeriesBible(SeriesState state) {
    return SeriesBible(
      seriesTitle: state.seriesTitle,
      pitch: state.storyArc,
      universe: state.universe,
      tone: state.tone,
      mainCharacters: state.mainCharacters,
      secondaryCharacters: state.secondaryCharacters,
      recurringPlaces: state.recurringPlaces,
      storyArc: state.storyArc,
      emotionalArc: state.emotionalArc,
      chapterPlan: state.chapterPlan,
      continuityRules: const [],
      antiRepetitionRules: state.antiRepetitionMemory,
      plannedEnding: state.storyArc,
    );
  }

  ChapterPlanItem? _planForChapter(SeriesState? state, int chapterIndex) {
    if (state == null) return null;
    for (final item in state.chapterPlan) {
      if (item.chapterIndex == chapterIndex) return item;
    }
    return null;
  }

  Future<SeriesState> _createSeriesState({
    required String stateDocId,
    required ChildProfile child,
    required UserModel user,
    required String seriesId,
    required SeriesBible bible,
    required int totalChapters,
  }) async {
    final now = DateTime.now();
    final state = SeriesState(
      id: stateDocId,
      childId: child.id,
      userId: user.id,
      status: 'active',
      seriesTitle: bible.seriesTitle,
      seriesFormat: child.storyFormat.wireValue,
      currentChapterIndex: 0,
      totalChapters: totalChapters,
      seriesDurationDays: child.seriesDurationDays,
      universe: bible.universe,
      tone: bible.tone,
      mainCharacters: bible.mainCharacters,
      secondaryCharacters: bible.secondaryCharacters,
      recurringPlaces: bible.recurringPlaces,
      storyArc: bible.storyArc,
      emotionalArc: bible.emotionalArc,
      chapterPlan: bible.chapterPlan,
      continuitySummary: bible.pitch,
      chapterSummaries: const [],
      openLoops: const [],
      resolvedLoops: const [],
      importantObjects: const [],
      emotionalProgression: const [],
      antiRepetitionMemory: bible.antiRepetitionRules,
      lastChapterSummary: '',
      nextChapterGoal: bible.chapterPlan.isEmpty ? '' : bible.chapterPlan.first.goal,
      createdAt: now,
      updatedAt: now,
    );
    await _db.collection(FirestorePaths.childSeriesState).doc(stateDocId).set({
      ...state.toMap(),
      'createdAt': Timestamp.fromDate(state.createdAt),
      'updatedAt': Timestamp.fromDate(state.updatedAt),
      'completedAt': null,
      'seriesId': seriesId,
    });
    return state;
  }

  Future<void> _updateSeriesStateAfterChapter({
    required String stateDocId,
    required SeriesState state,
    required int chapterIndex,
    required Story story,
    required ChapterContinuityUpdate? continuityUpdate,
  }) async {
    final safeSummary = continuityUpdate?.chapterSummary.trim().isNotEmpty == true
        ? continuityUpdate!.chapterSummary.trim()
        : story.summary;
    final update = continuityUpdate ??
        ChapterContinuityUpdate(
          chapterSummary: safeSummary,
          importantEvents: const [],
          charactersMet: const [],
          objectsIntroduced: const [],
          resolvedLoops: const [],
          openLoops: const [],
          emotionalStep: '',
          thingsToRemember: const [],
          thingsToAvoidRepeating: const [],
          nextChapterGoal: '',
        );

    final mergedSummaries = [...state.chapterSummaries, safeSummary];
    final mergedObjects = {...state.importantObjects, ...update.objectsIntroduced}.toList();
    final mergedResolved = {...state.resolvedLoops, ...update.resolvedLoops}.toList();
    final mergedOpen = {
      ...state.openLoops.where((loop) => !update.resolvedLoops.contains(loop)),
      ...update.openLoops,
    }.toList();
    final mergedEmotions = update.emotionalStep.trim().isEmpty
        ? state.emotionalProgression
        : [...state.emotionalProgression, update.emotionalStep.trim()];
    final antiRep = {
      ...state.antiRepetitionMemory,
      ...update.thingsToAvoidRepeating,
    }.toList();

    final isCompleted = chapterIndex >= state.totalChapters;
    final now = DateTime.now();
    try {
      await _db.collection(FirestorePaths.childSeriesState).doc(stateDocId).set({
        'currentChapterIndex': chapterIndex,
        'status': isCompleted ? 'completed' : 'active',
        'chapterSummaries': mergedSummaries,
        'continuitySummary': mergedSummaries.take(6).join(' | '),
        'lastChapterSummary': safeSummary,
        'importantObjects': mergedObjects,
        'resolvedLoops': mergedResolved,
        'openLoops': isCompleted ? const <String>[] : mergedOpen,
        'emotionalProgression': mergedEmotions,
        'antiRepetitionMemory': antiRep,
        'nextChapterGoal': isCompleted ? 'Série terminée' : update.nextChapterGoal,
        'updatedAt': Timestamp.fromDate(now),
        'completedAt': isCompleted ? Timestamp.fromDate(now) : null,
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Series continuity update skipped for $stateDocId: $e');
      }
    }
  }

  Future<StoryMemoryContext?> _safeBuildMemoryContext({
    required UserModel user,
    required ChildProfile child,
    required int chapterIndex,
    required int totalChapters,
  }) async {
    try {
      final storyWorld = await _memoryRepository.getOrCreateWorld(
        user: user,
        child: child,
      );
      final snapshots = await _memoryRepository.getRecentSnapshots(
        child.id,
        limit: 3,
      );
      return StoryMemoryBuilder.build(
        storyWorld: storyWorld,
        recentSnapshots: snapshots,
        child: child,
        chapterIndex: chapterIndex,
        totalChapters: totalChapters,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Memory context skipped for child ${child.id}: $e');
      }
      return null;
    }
  }

  Future<void> _safeUpdateMemoryAfterStorySaved({
    required Story story,
    required ChildProfile child,
    required UserModel user,
  }) async {
    try {
      final world = await _memoryRepository.getOrCreateWorld(user: user, child: child);
      await StoryMemoryUpdater.afterStorySaved(
        repository: _memoryRepository,
        story: story,
        child: child,
        worldBefore: world,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Memory update skipped after story ${story.id}: $e');
      }
    }
  }
}
