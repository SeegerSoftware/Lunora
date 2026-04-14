import '../../../services/mock/lunora_mock_store.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import 'child_profile_repository.dart';

class MockChildProfileRepository implements ChildProfileRepository {
  MockChildProfileRepository({required LunoraMockStore store}) : _store = store;

  final LunoraMockStore _store;

  @override
  Future<void> clear() async {
    _store.childProfile = null;
  }

  @override
  Future<ChildProfile?> fetchForUser(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final current = _store.childProfile;
    if (current == null) return null;
    if (current.userId != userId) return null;
    return current;
  }

  @override
  Future<void> upsert(ChildProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (profile.storyFormat == StoryFormat.dailyStandalone) {
      _store.clearSeriesAnchor(profile.id);
    }
    _store.childProfile = profile;
  }
}
