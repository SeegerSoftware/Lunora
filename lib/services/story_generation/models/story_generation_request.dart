import 'package:equatable/equatable.dart';

import '../../../features/story_memory/domain/story_memory_context.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/series_state.dart';
import '../../../shared/models/user_model.dart';

class StoryGenerationRequest extends Equatable {
  const StoryGenerationRequest({
    required this.user,
    required this.child,
    required this.dateKey,
    required this.chapterIndex,
    required this.totalChapters,
    this.seriesId,
    this.continuityContext,
    this.seriesFilRougeBlock,
    this.memoryContext,
    this.seriesBible,
    this.seriesState,
    this.currentChapterPlan,
  });

  final UserModel user;
  final ChildProfile child;
  final String dateKey;

  /// 1-based chapter index for serialized stories.
  final int chapterIndex;
  final int totalChapters;
  final String? seriesId;

  /// Résumés / extraits des chapitres précédents (série), construit côté repository.
  final String? continuityContext;

  /// Bloc « fil rouge » stable (compagnon, objet, objectif), construit côté repository.
  final String? seriesFilRougeBlock;

  /// Mémoire long terme + récente (univers persistant par enfant).
  final StoryMemoryContext? memoryContext;
  final SeriesBible? seriesBible;
  final SeriesState? seriesState;
  final ChapterPlanItem? currentChapterPlan;

  @override
  List<Object?> get props => [
        user,
        child,
        dateKey,
        chapterIndex,
        totalChapters,
        seriesId,
        continuityContext,
        seriesFilRougeBlock,
        memoryContext,
        seriesBible,
        seriesState,
        currentChapterPlan,
      ];
}
