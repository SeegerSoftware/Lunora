import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../shared/models/subscription.dart';
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

}
