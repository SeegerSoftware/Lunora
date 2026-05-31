import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/config/admin_config.dart';
import '../../../core/utils/date_key_utils.dart';
import '../../story_memory/domain/story_memory_context.dart';
import '../../story_memory/data/story_memory_repository.dart';
import '../../story_memory/services/story_memory_builder.dart';
import '../../story_memory/services/story_memory_updater.dart';
import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_mappers.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../services/story_generation/models/story_generation_request.dart';
import '../../../services/story_generation/models/story_generation_result.dart';
import '../../../services/story_generation/story_generation_exception.dart';
import '../../../services/story_generation/story_generation_service.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import '../../../shared/models/series_state.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_model.dart';
import 'series_state_reducer.dart';
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
  Future<void> preserveActiveSeriesProfile({
    required UserModel user,
    required ChildProfile child,
  }) async {
    final stateDocId = _seriesStateDocId(childId: child.id, userId: user.id);
    final state = await _loadSeriesState(stateDocId);
    if (state == null ||
        state.status != 'active' ||
        state.profileSnapshot != null) {
      return;
    }
    final updated = state.copyWith(
      profileSnapshot: child,
      updatedAt: DateTime.now(),
    );
    await _db
        .collection(FirestorePaths.childSeriesState)
        .doc(stateDocId)
        .set(_seriesStateWrite(updated), SetOptions(merge: true));
  }

  @override
  Future<void> restartActiveSeries({
    required UserModel user,
    required ChildProfile child,
  }) async {
    final now = DateTime.now();
    final todayKey = DateKeyUtils.todayKey();
    final stateDocId = _seriesStateDocId(childId: child.id, userId: user.id);
    final stateRef = _db
        .collection(FirestorePaths.childSeriesState)
        .doc(stateDocId);
    final storyRef = _db
        .collection(FirestorePaths.stories)
        .doc(
          _todayStoryDocId(
            userId: user.id,
            childId: child.id,
            dateKey: todayKey,
          ),
        );
    final state = await _loadSeriesState(stateDocId);
    final story = await storyRef.get();
    final batch = _db.batch();
    var hasWrites = false;

    if (story.exists && story.data() != null) {
      final archiveId =
          '${story.id}_archived_${now.toUtc().microsecondsSinceEpoch}';
      batch.set(
        _db.collection(FirestorePaths.stories).doc(archiveId),
        story.data()!,
      );
      batch.delete(storyRef);
      hasWrites = true;
    }
    if (state != null && state.status == 'active') {
      batch.set(
        stateRef,
        _seriesStateWrite(
          state.copyWith(status: 'cancelled', updatedAt: now, completedAt: now),
        ),
        SetOptions(merge: true),
      );
      hasWrites = true;
    }
    if (hasWrites) await batch.commit();
  }

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
  Future<void> setStoryUserFeedback({
    required String storyId,
    required int feedback,
  }) async {
    if (feedback != 1 && feedback != -1) {
      throw ArgumentError.value(feedback, 'feedback', 'attendu 1 ou -1');
    }
    try {
      await _db.collection(FirestorePaths.stories).doc(storyId).update({
        'userFeedback': feedback,
        'userFeedbackAt': FieldValue.serverTimestamp(),
      });
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
          .limit(100)
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
  Future<Story?> findTodayStory({
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
      final snap = await _db
          .collection(FirestorePaths.stories)
          .doc(storyId)
          .get();
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return Story.fromMap({...data, 'id': snap.id});
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
      if (existingSnap != null &&
          existingSnap.exists &&
          existingSnap.data() != null) {
        final m = Map<String, dynamic>.from(existingSnap.data()!);
        m['id'] = existingSnap.id;
        final cached = Story.fromMap(m);
        // Ne jamais régénérer automatiquement à la reconnexion :
        // conserver l’histoire existante pour une expérience stable.
        return cached;
      }

      final isSerialized = child.storyFormat == StoryFormat.serializedChapters;

      late final int chapterIndex;
      late final int totalChapters;
      late final String? seriesId;
      var generationChild = child;
      SeriesState? activeSeriesState;
      SeriesBible? seriesBible;
      ChapterPlanItem? currentChapterPlan;

      if (!isSerialized) {
        chapterIndex = 1;
        totalChapters = 1;
        seriesId = null;
      } else {
        final seriesStateDocId = _seriesStateDocId(
          childId: child.id,
          userId: user.id,
        );
        activeSeriesState = await _loadSeriesState(seriesStateDocId);
        if (activeSeriesState == null ||
            activeSeriesState.status != 'active' ||
            activeSeriesState.currentChapterIndex >=
                activeSeriesState.totalChapters) {
          seriesId = _newSeriesId(childId: child.id, dateKey: todayKey);
          totalChapters = child.seriesDurationDays;
          final bibleRequest = StoryGenerationRequest(
            user: user,
            child: generationChild,
            dateKey: todayKey,
            chapterIndex: 1,
            totalChapters: totalChapters,
            seriesId: seriesId,
          );
          seriesBible = await _generationService.generateSeriesBible(
            bibleRequest,
          );
          activeSeriesState = await _createSeriesState(
            stateDocId: seriesStateDocId,
            child: child,
            user: user,
            seriesId: seriesId,
            bible: seriesBible,
            totalChapters: totalChapters,
          );
        } else {
          generationChild = activeSeriesState.profileSnapshot ?? child;
          totalChapters = activeSeriesState.totalChapters;
          seriesId = activeSeriesState.seriesId;
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
        child: generationChild,
        chapterIndex: chapterIndex,
        totalChapters: totalChapters,
      );

      final request = StoryGenerationRequest(
        user: user,
        child: generationChild,
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

      if (isSerialized && activeSeriesState != null) {
        final nextState = SeriesStateReducer.advance(
          state: activeSeriesState,
          chapterIndex: chapterIndex,
          fallbackSummary: story.summary,
          continuityUpdate: generated.continuityUpdate,
          now: DateTime.now(),
        );
        final batch = _db.batch();
        batch.set(ref, FirestoreMappers.storyWrite(story));
        batch.set(
          _db
              .collection(FirestorePaths.childSeriesState)
              .doc(activeSeriesState.id),
          _seriesStateWrite(nextState),
          SetOptions(merge: true),
        );
        await batch.commit();
      } else {
        await ref.set(FirestoreMappers.storyWrite(story));
      }

      await _safeUpdateMemoryAfterStorySaved(
        story: story,
        child: generationChild,
        user: user,
      );

      return story;
    } catch (e) {
      if (e is StoryGenerationException) rethrow;
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<Story> adminRegenerateTodayStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _assertAdmin(user);
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
      final existing = await storyRef.get();
      final existingData = existing.data();
      final existingStory = existing.exists && existingData != null
          ? Story.fromMap({...existingData, 'id': existing.id})
          : null;
      if (existingStory?.isSerialized == true) {
        await _rewindSeriesForRegeneration(existingStory!);
      } else {
        await _safeDeleteDoc(storyRef);
      }
      await _safeDeleteDoc(snapRef);
      return ensureTodayStory(user: user, child: child);
    } catch (e) {
      if (e is StoryGenerationException) rethrow;
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<Story> adminGenerateUniqueStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _assertAdmin(user);
    final dateKey = DateKeyUtils.todayKey();
    final suffix = _adminGenerationSuffix();
    final standaloneChild = child.copyWith(
      storyFormat: StoryFormat.dailyStandalone,
      seriesDurationDays: 0,
    );
    try {
      final memoryContext = await _safeBuildMemoryContext(
        user: user,
        child: standaloneChild,
        chapterIndex: 1,
        totalChapters: 1,
      );
      final generated = await _generationService.generate(
        StoryGenerationRequest(
          user: user,
          child: standaloneChild,
          dateKey: dateKey,
          chapterIndex: 1,
          totalChapters: 1,
          memoryContext: memoryContext,
        ),
      );
      final story = _storyFromGeneration(
        id: 'story_${user.id}_${child.id}_${dateKey}_admin_$suffix',
        child: standaloneChild,
        user: user,
        dateKey: dateKey,
        generated: generated,
        chapterIndex: 1,
        totalChapters: 1,
      );
      await _db
          .collection(FirestorePaths.stories)
          .doc(story.id)
          .set(FirestoreMappers.storyWrite(story));
      await _safeUpdateMemoryAfterStorySaved(
        story: story,
        child: standaloneChild,
        user: user,
      );
      return story;
    } catch (e) {
      if (e is StoryGenerationException) rethrow;
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<List<Story>> adminGenerateSevenChapterStory({
    required UserModel user,
    required ChildProfile child,
  }) async {
    _assertAdmin(user);
    const totalChapters = 7;
    final dateKey = DateKeyUtils.todayKey();
    final suffix = _adminGenerationSuffix();
    final seriesId = 'series_${child.id}_${dateKey}_admin_$suffix';
    final stateDocId = 'admin_${child.id}_${user.id}_$suffix';
    final serializedChild = child.copyWith(
      storyFormat: StoryFormat.serializedChapters,
      seriesDurationDays: totalChapters,
    );

    try {
      final bibleRequest = StoryGenerationRequest(
        user: user,
        child: serializedChild,
        dateKey: dateKey,
        chapterIndex: 1,
        totalChapters: totalChapters,
        seriesId: seriesId,
      );
      final bible = await _generationService.generateSeriesBible(bibleRequest);
      var state = await _createSeriesState(
        stateDocId: stateDocId,
        child: serializedChild,
        user: user,
        seriesId: seriesId,
        bible: bible,
        totalChapters: totalChapters,
      );
      final stories = <Story>[];

      for (
        var chapterIndex = 1;
        chapterIndex <= totalChapters;
        chapterIndex++
      ) {
        final memoryContext = await _safeBuildMemoryContext(
          user: user,
          child: serializedChild,
          chapterIndex: chapterIndex,
          totalChapters: totalChapters,
        );
        final generated = await _generationService.generate(
          StoryGenerationRequest(
            user: user,
            child: serializedChild,
            dateKey: dateKey,
            chapterIndex: chapterIndex,
            totalChapters: totalChapters,
            seriesId: seriesId,
            continuityContext: state.continuitySummary,
            memoryContext: memoryContext,
            seriesBible: bible,
            seriesState: state,
            currentChapterPlan: _planForChapter(state, chapterIndex),
          ),
        );
        final story = _storyFromGeneration(
          id: 'story_${user.id}_${child.id}_${dateKey}_admin_${suffix}_chapter_$chapterIndex',
          child: serializedChild,
          user: user,
          dateKey: dateKey,
          generated: generated,
          chapterIndex: chapterIndex,
          totalChapters: totalChapters,
          seriesId: seriesId,
        );
        state = SeriesStateReducer.advance(
          state: state,
          chapterIndex: chapterIndex,
          fallbackSummary: story.summary,
          continuityUpdate: generated.continuityUpdate,
          now: DateTime.now(),
        );
        final batch = _db.batch();
        batch.set(
          _db.collection(FirestorePaths.stories).doc(story.id),
          FirestoreMappers.storyWrite(story),
        );
        batch.set(
          _db.collection(FirestorePaths.childSeriesState).doc(stateDocId),
          _seriesStateWrite(state),
          SetOptions(merge: true),
        );
        await batch.commit();
        stories.add(story);
        await _safeUpdateMemoryAfterStorySaved(
          story: story,
          child: serializedChild,
          user: user,
        );
      }
      return stories;
    } catch (e) {
      if (e is StoryGenerationException) rethrow;
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  Future<void> _safeDeleteDoc(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
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

  String _seriesStateDocId({required String childId, required String userId}) {
    return '${childId}_$userId';
  }

  String _newSeriesId({required String childId, required String dateKey}) {
    return 'series_${childId}_${dateKey}_${DateTime.now().toUtc().microsecondsSinceEpoch}';
  }

  String _adminGenerationSuffix() {
    return DateTime.now().toUtc().microsecondsSinceEpoch.toString();
  }

  void _assertAdmin(UserModel user) {
    if (!AdminConfig.isAdminUser(user)) {
      throw StateError('Action reservee au compte administrateur.');
    }
  }

  Story _storyFromGeneration({
    required String id,
    required ChildProfile child,
    required UserModel user,
    required String dateKey,
    required StoryGenerationResult generated,
    required int chapterIndex,
    required int totalChapters,
    String? seriesId,
  }) {
    return Story(
      id: id,
      childId: child.id,
      userId: user.id,
      dateKey: dateKey,
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
  }

  Future<void> _rewindSeriesForRegeneration(Story story) async {
    final stateDocId = _seriesStateDocId(
      childId: story.childId,
      userId: story.userId,
    );
    final state = await _loadSeriesState(stateDocId);
    final storyRef = _db.collection(FirestorePaths.stories).doc(story.id);
    if (state == null ||
        state.seriesId != story.seriesId ||
        state.currentChapterIndex != story.chapterNumber) {
      await _safeDeleteDoc(storyRef);
      return;
    }
    final rewound = SeriesStateReducer.rewindCurrentChapter(
      state: state,
      chapterIndex: story.chapterNumber,
      now: DateTime.now(),
    );
    final batch = _db.batch();
    batch.delete(storyRef);
    batch.set(
      _db.collection(FirestorePaths.childSeriesState).doc(stateDocId),
      _seriesStateWrite(rewound),
      SetOptions(merge: true),
    );
    await batch.commit();
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
      antiRepetitionRules: state.antiRepetitionRules,
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
      seriesId: seriesId,
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
      antiRepetitionRules: bible.antiRepetitionRules,
      chapterContinuityUpdates: const [],
      lastChapterSummary: '',
      nextChapterGoal: bible.chapterPlan.isEmpty
          ? ''
          : bible.chapterPlan.first.goal,
      createdAt: now,
      updatedAt: now,
      profileSnapshot: child,
    );
    await _db.collection(FirestorePaths.childSeriesState).doc(stateDocId).set({
      ...state.toMap(),
      'createdAt': Timestamp.fromDate(state.createdAt),
      'updatedAt': Timestamp.fromDate(state.updatedAt),
      'completedAt': null,
    });
    return state;
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

  Map<String, dynamic> _seriesStateWrite(SeriesState state) {
    return {
      ...state.toMap(),
      'createdAt': Timestamp.fromDate(state.createdAt),
      'updatedAt': Timestamp.fromDate(state.updatedAt),
      'completedAt': state.completedAt == null
          ? null
          : Timestamp.fromDate(state.completedAt!),
    };
  }

  Future<void> _safeUpdateMemoryAfterStorySaved({
    required Story story,
    required ChildProfile child,
    required UserModel user,
  }) async {
    try {
      final world = await _memoryRepository.getOrCreateWorld(
        user: user,
        child: child,
      );
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
