import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_mappers.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../shared/models/child_profile.dart';
import '../../../shared/models/enums/story_format.dart';
import 'child_profile_repository.dart';

class FirebaseChildProfileRepository implements ChildProfileRepository {
  FirebaseChildProfileRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> clear() async {}

  @override
  Future<ChildProfile?> fetchForUser(String userId) async {
    try {
      final query = await _db
          .collection(FirestorePaths.childrenProfiles)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      final data = Map<String, dynamic>.from(doc.data());
      data['id'] = doc.id;
      return ChildProfile.fromMap(data);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<void> upsert(ChildProfile profile) async {
    try {
      await _db
          .collection(FirestorePaths.childrenProfiles)
          .doc(profile.id)
          .set(
            FirestoreMappers.childProfileWrite(profile),
            SetOptions(merge: true),
          );

      if (profile.storyFormat == StoryFormat.dailyStandalone) {
        await _safeDeleteSeriesStateDoc(profile.id);
        await _safeDeleteSeriesStateDoc('${profile.id}_${profile.userId}');
      }
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  Future<void> _safeDeleteSeriesStateDoc(String docId) async {
    try {
      await _db.collection(FirestorePaths.childSeriesState).doc(docId).delete();
    } catch (_) {
      // Tolérance legacy: on n'empêche pas la sauvegarde du profil.
    }
  }
}
