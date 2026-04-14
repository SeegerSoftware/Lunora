import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/user_model.dart';
import '../domain/story_memory_snapshot.dart';
import '../domain/story_world.dart';
import '../services/story_world_seed.dart';
import 'story_memory_repository.dart';

class FirebaseStoryMemoryRepository implements StoryMemoryRepository {
  FirebaseStoryMemoryRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<StoryWorld> getOrCreateWorld({
    required UserModel user,
    required ChildProfile child,
  }) async {
    try {
      final ref = _db.collection(FirestorePaths.storyWorlds).doc(child.id);
      final snap = await ref.get();
      if (snap.exists && snap.data() != null) {
        return StoryWorld.fromFirestore(snap.id, snap.data()!);
      }

      final legacy = await _db
          .collection(FirestorePaths.childSeriesState)
          .doc(child.id)
          .get();
      final ld = legacy.data();
      final lc = ld?['seriesCompanion'] as String?;
      final lm = ld?['seriesMagicObject'] as String?;
      final lg = ld?['seriesGlobalObjective'] as String?;

      final initial = StoryWorldSeed.initial(
        child: child,
        user: user,
        legacyCompanion: lc,
        legacyMagicItem: lm,
        legacyCoreGoal: lg,
      );
      await ref.set(initial.toFirestoreMap());
      return initial;
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<List<StoryMemorySnapshot>> getRecentSnapshots(
    String childId, {
    int limit = 3,
  }) async {
    try {
      final q = await _db
          .collection(FirestorePaths.storyMemorySnapshots)
          .where('childId', isEqualTo: childId)
          .limit(24)
          .get();
      final list = q.docs
          .map((d) => StoryMemorySnapshot.fromFirestore(d.id, d.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (list.length <= limit) return list;
      return list.sublist(0, limit);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<void> saveSnapshot(StoryMemorySnapshot snapshot) async {
    try {
      await _db
          .collection(FirestorePaths.storyMemorySnapshots)
          .doc(snapshot.storyId)
          .set(snapshot.toFirestoreMap());
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<void> updateWorld(StoryWorld world) async {
    try {
      await _db
          .collection(FirestorePaths.storyWorlds)
          .doc(world.childId)
          .set(world.toFirestoreMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }
}
