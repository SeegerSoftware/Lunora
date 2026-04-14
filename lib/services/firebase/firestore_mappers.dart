import 'package:cloud_firestore/cloud_firestore.dart';

import '../../shared/models/child_profile.dart';
import '../../shared/models/enums/subscription_status.dart';
import '../../shared/models/story.dart';
import '../../shared/models/subscription.dart';
import '../../shared/models/user_model.dart';

/// Conversion Firestore (Timestamp) sans modifier les `toMap()` métier ISO.
abstract final class FirestoreMappers {
  static Map<String, dynamic> userWrite(UserModel u) {
    return {
      'id': u.id,
      'email': u.email,
      'createdAt': Timestamp.fromDate(u.createdAt),
      'selectedPlan': u.selectedPlan,
      'subscriptionStatus': u.subscriptionStatus.wireValue,
    };
  }

  static Map<String, dynamic> childProfileWrite(ChildProfile p) {
    final m = Map<String, dynamic>.from(p.toMap());
    m['createdAt'] = Timestamp.fromDate(p.createdAt);
    m['updatedAt'] = Timestamp.fromDate(p.updatedAt);
    return m;
  }

  static Map<String, dynamic> storyWrite(Story s) {
    final m = Map<String, dynamic>.from(s.toMap());
    m['createdAt'] = Timestamp.fromDate(s.createdAt);
    return m;
  }

  static Map<String, dynamic> subscriptionWrite(Subscription s) {
    final m = Map<String, dynamic>.from(s.toMap());
    m['startedAt'] = Timestamp.fromDate(s.startedAt);
    m['endsAt'] = s.endsAt != null ? Timestamp.fromDate(s.endsAt!) : null;
    return m;
  }
}
