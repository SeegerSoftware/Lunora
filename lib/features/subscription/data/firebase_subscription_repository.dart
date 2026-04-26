import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_mappers.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../shared/models/enums/renewal_type.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_model.dart';
import 'subscription_repository.dart';

class FirebaseSubscriptionRepository implements SubscriptionRepository {
  FirebaseSubscriptionRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> clear() async {}

  @override
  Future<Subscription?> current(String userId) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.subscriptions)
          .doc(userId)
          .get();
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      data['userId'] = userId;
      return Subscription.fromMap(data);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<Subscription> activateTestPlan({
    required UserModel user,
    required StoryPlan plan,
  }) async {
    try {
      final now = DateTime.now();
      final sub = Subscription(
        userId: user.id,
        planId: plan.planId,
        status: SubscriptionStatus.active,
        startedAt: now,
        endsAt: now.add(const Duration(days: 30)),
        renewalType: RenewalType.monthly,
      );

      final batch = _db.batch();
      batch.set(
        _db.collection(FirestorePaths.subscriptions).doc(user.id),
        FirestoreMappers.subscriptionWrite(sub),
      );
      batch.set(_db.collection(FirestorePaths.users).doc(user.id), {
        'selectedPlan': plan.planId,
        'subscriptionStatus': SubscriptionStatus.active.wireValue,
      }, SetOptions(merge: true));
      await batch.commit();
      return sub;
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }
}
