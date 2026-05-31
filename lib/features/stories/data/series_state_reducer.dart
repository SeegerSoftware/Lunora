import '../../../shared/models/series_state.dart';
import '../../../shared/models/narrative_memory.dart';

abstract final class SeriesStateReducer {
  static SeriesState advance({
    required SeriesState state,
    required int chapterIndex,
    required String fallbackSummary,
    required ChapterContinuityUpdate? continuityUpdate,
    required DateTime now,
  }) {
    final update = _normalizedUpdate(
      continuityUpdate: continuityUpdate,
      fallbackSummary: fallbackSummary,
    );
    return _rebuild(
      state: state,
      updates: [...state.chapterContinuityUpdates, update],
      legacySummaries: [...state.chapterSummaries, update.chapterSummary],
      currentChapterIndex: chapterIndex,
      now: now,
    );
  }

  static SeriesState rewindCurrentChapter({
    required SeriesState state,
    required int chapterIndex,
    required DateTime now,
  }) {
    if (chapterIndex != state.currentChapterIndex || chapterIndex <= 0) {
      return state;
    }
    final updates = [...state.chapterContinuityUpdates];
    if (updates.isNotEmpty) updates.removeLast();
    final summaries = [...state.chapterSummaries];
    if (summaries.isNotEmpty) summaries.removeLast();
    return _rebuild(
      state: state,
      updates: updates,
      legacySummaries: summaries,
      currentChapterIndex: chapterIndex - 1,
      now: now,
    );
  }

  static SeriesState _rebuild({
    required SeriesState state,
    required List<ChapterContinuityUpdate> updates,
    required List<String> legacySummaries,
    required int currentChapterIndex,
    required DateTime now,
  }) {
    final summaries = legacySummaries;
    final openLoops = <String>{};
    final resolvedLoops = <String>{};
    final importantObjects = <String>{};
    final emotionalProgression = <String>[];
    final antiRepetitionMemory = <String>{...state.antiRepetitionRules};
    for (final update in updates) {
      resolvedLoops.addAll(update.resolvedLoops);
      openLoops
        ..removeAll(update.resolvedLoops)
        ..addAll(update.openLoops);
      importantObjects.addAll(update.objectsIntroduced);
      if (update.emotionalStep.trim().isNotEmpty) {
        emotionalProgression.add(update.emotionalStep.trim());
      }
      antiRepetitionMemory.addAll(update.thingsToAvoidRepeating);
      antiRepetitionMemory.addAll(update.doNotRepeat);
    }
    final isCompleted = currentChapterIndex >= state.totalChapters;
    final recentSummaries = summaries.length <= 6
        ? summaries
        : summaries.sublist(summaries.length - 6);
    final nextPlan = state.chapterPlan
        .where((item) => item.chapterIndex == currentChapterIndex + 1)
        .firstOrNull;
    final nextGoal = updates.isNotEmpty
        ? updates.last.nextChapterGoal.trim()
        : nextPlan?.goal.trim() ?? '';

    final hasCompleteContinuityHistory = updates.length == currentChapterIndex;
    return state.copyWith(
      currentChapterIndex: currentChapterIndex,
      status: isCompleted ? 'completed' : 'active',
      chapterSummaries: summaries,
      continuitySummary: recentSummaries.join(' | '),
      lastChapterSummary: summaries.isEmpty ? '' : summaries.last,
      importantObjects: !hasCompleteContinuityHistory
          ? state.importantObjects
          : importantObjects.toList(),
      resolvedLoops: !hasCompleteContinuityHistory
          ? state.resolvedLoops
          : resolvedLoops.toList(),
      openLoops: isCompleted
          ? const []
          : !hasCompleteContinuityHistory
          ? state.openLoops
          : openLoops.toList(),
      emotionalProgression: !hasCompleteContinuityHistory
          ? state.emotionalProgression
          : emotionalProgression,
      antiRepetitionMemory: !hasCompleteContinuityHistory
          ? state.antiRepetitionMemory
          : antiRepetitionMemory.toList(),
      relations: updates.expand((item) => item.relations).take(24).toList(),
      mysteries: updates.expand((item) => item.mysteries).take(24).toList(),
      narrativeObjects: updates
          .expand((item) => item.narrativeObjects)
          .take(32)
          .toList(),
      emotions: updates.isEmpty
          ? state.emotions
          : updates.last.emotions == const EmotionalProgress()
          ? state.emotions
          : updates.last.emotions,
      majorEvents: updates.expand((item) => item.majorEvents).take(40).toList(),
      doNotRepeat: antiRepetitionMemory.take(40).toList(),
      chapterContinuityUpdates: updates,
      nextChapterGoal: isCompleted ? 'Série terminée' : nextGoal,
      updatedAt: now,
      completedAt: isCompleted ? now : null,
      clearCompletedAt: !isCompleted,
    );
  }

  static ChapterContinuityUpdate _normalizedUpdate({
    required ChapterContinuityUpdate? continuityUpdate,
    required String fallbackSummary,
  }) {
    final summary = continuityUpdate?.chapterSummary.trim().isNotEmpty == true
        ? continuityUpdate!.chapterSummary.trim()
        : fallbackSummary.trim();
    return ChapterContinuityUpdate(
      chapterSummary: summary,
      importantEvents: continuityUpdate?.importantEvents ?? const [],
      charactersMet: continuityUpdate?.charactersMet ?? const [],
      objectsIntroduced: continuityUpdate?.objectsIntroduced ?? const [],
      resolvedLoops: continuityUpdate?.resolvedLoops ?? const [],
      openLoops: continuityUpdate?.openLoops ?? const [],
      emotionalStep: continuityUpdate?.emotionalStep ?? '',
      thingsToRemember: continuityUpdate?.thingsToRemember ?? const [],
      thingsToAvoidRepeating:
          continuityUpdate?.thingsToAvoidRepeating ?? const [],
      nextChapterGoal: continuityUpdate?.nextChapterGoal ?? '',
      relations: continuityUpdate?.relations ?? const [],
      mysteries: continuityUpdate?.mysteries ?? const [],
      narrativeObjects: continuityUpdate?.narrativeObjects ?? const [],
      emotions: continuityUpdate?.emotions ?? statePlaceholderEmotions,
      majorEvents: continuityUpdate?.majorEvents ?? const [],
      doNotRepeat: continuityUpdate?.doNotRepeat ?? const [],
    );
  }

  static const statePlaceholderEmotions = EmotionalProgress();
}
