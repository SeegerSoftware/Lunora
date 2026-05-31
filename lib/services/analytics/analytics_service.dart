import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract final class AnalyticsEvents {
  static const accountCreated = 'account_created';
  static const loginSuccess = 'login_success';
  static const childCreated = 'child_created';
  static const childUpdated = 'child_updated';
  static const storyGenerated = 'story_generated';
  static const storyOpened = 'story_opened';
  static const storyFinished = 'story_finished';
  static const storyLiked = 'story_liked';
  static const storyDisliked = 'story_disliked';
  static const subscriptionStarted = 'subscription_started';
  static const subscriptionCancelled = 'subscription_cancelled';
  static const paymentSuccess = 'payment_success';
  static const paymentFailed = 'payment_failed';
  static const libraryOpened = 'library_opened';
  static const readerOpened = 'reader_opened';
  static const readerClosed = 'reader_closed';
  static const accountDeleted = 'account_deleted';
}

class AnalyticsService {
  AnalyticsService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<void> log(
    String name, {
    Map<String, Object?> parameters = const {},
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('product_analytics_events').add({
      'eventName': name,
      'userId': user.uid,
      'parameters': parameters,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
