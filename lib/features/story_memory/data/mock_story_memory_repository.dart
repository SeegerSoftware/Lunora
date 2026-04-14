import '../../../services/mock/lunora_mock_store.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/user_model.dart';
import '../domain/story_memory_snapshot.dart';
import '../domain/story_world.dart';
import 'story_memory_repository.dart';

class MockStoryMemoryRepository implements StoryMemoryRepository {
  MockStoryMemoryRepository({required LunoraMockStore store}) : _store = store;

  final LunoraMockStore _store;

  @override
  Future<StoryWorld> getOrCreateWorld({
    required UserModel user,
    required ChildProfile child,
  }) async {
    return _store.getOrCreateStoryWorld(user: user, child: child);
  }

  @override
  Future<List<StoryMemorySnapshot>> getRecentSnapshots(
    String childId, {
    int limit = 3,
  }) async {
    return _store.recentMemorySnapshots(childId, limit: limit);
  }

  @override
  Future<void> saveSnapshot(StoryMemorySnapshot snapshot) async {
    _store.putMemorySnapshot(snapshot);
  }

  @override
  Future<void> updateWorld(StoryWorld world) async {
    _store.putStoryWorld(world);
  }
}
