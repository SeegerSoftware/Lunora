import '../../../shared/models/child_profile.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_model.dart';

abstract class StoryRepository {
  Future<Story> ensureTodayStory({
    required UserModel user,
    required ChildProfile child,
  });

  /// Supprime l’histoire « du jour » puis en génère une nouvelle (compte admin uniquement).
  Future<Story> adminRegenerateTodayStory({
    required UserModel user,
    required ChildProfile child,
  });

  Future<List<Story>> historyForUser(String userId);

  Future<Story?> findById(String storyId);

  /// [feedback] : 1 = j’aime, -1 = je n’aime pas.
  Future<void> setStoryUserFeedback({
    required String storyId,
    required int feedback,
  });

  Future<void> reset();
}
