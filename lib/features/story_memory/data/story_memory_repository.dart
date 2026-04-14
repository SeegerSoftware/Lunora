import '../../../shared/models/child_profile.dart';
import '../../../shared/models/user_model.dart';
import '../domain/story_memory_snapshot.dart';
import '../domain/story_world.dart';

/// Persistance de l’univers narratif et des snapshots mémoire par enfant.
abstract class StoryMemoryRepository {
  Future<StoryWorld> getOrCreateWorld({
    required UserModel user,
    required ChildProfile child,
  });

  /// Dernières entrées les plus récentes (tri décroissant par [StoryMemorySnapshot.createdAt]).
  Future<List<StoryMemorySnapshot>> getRecentSnapshots(
    String childId, {
    int limit = 3,
  });

  Future<void> saveSnapshot(StoryMemorySnapshot snapshot);

  Future<void> updateWorld(StoryWorld world);
}
