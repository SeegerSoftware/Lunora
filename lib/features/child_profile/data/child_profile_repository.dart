import '../../../shared/models/child_profile.dart';

abstract class ChildProfileRepository {
  Future<ChildProfile?> fetchForUser(String userId);

  Future<void> upsert(ChildProfile profile);

  Future<void> clear();
}
