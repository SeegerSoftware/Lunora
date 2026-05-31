import '../../../shared/models/child_profile.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_model.dart';

abstract class StoryRepository {
  /// Lit l'histoire publiee pour aujourd'hui sans lancer de generation.
  Future<Story?> findTodayStory({
    required UserModel user,
    required ChildProfile child,
  });

  Future<Story> ensureTodayStory({
    required UserModel user,
    required ChildProfile child,
  });

  /// Fige les réglages utilisés par une série active créée avant les snapshots.
  Future<void> preserveActiveSeriesProfile({
    required UserModel user,
    required ChildProfile child,
  });

  /// Clôt la série active et archive l'histoire du jour sans effacer l'historique.
  Future<void> restartActiveSeries({
    required UserModel user,
    required ChildProfile child,
  });

  /// Supprime l’histoire « du jour » puis en génère une nouvelle (compte admin uniquement).
  Future<Story> adminRegenerateTodayStory({
    required UserModel user,
    required ChildProfile child,
  });

  /// Genere une histoire independante supplementaire, sans remplacer celle du jour.
  Future<Story> adminGenerateUniqueStory({
    required UserModel user,
    required ChildProfile child,
  });

  /// Genere et archive immediatement une serie complete de 7 chapitres.
  Future<List<Story>> adminGenerateSevenChapterStory({
    required UserModel user,
    required ChildProfile child,
  });

  Future<List<Story>> historyForChild({
    required String userId,
    required String childId,
  });

  Future<Story?> findById(String storyId);

  /// [feedback] : 1 = j’aime, -1 = je n’aime pas.
  Future<void> setStoryUserFeedback({
    required String storyId,
    required int feedback,
  });

  Future<void> reset();
}
