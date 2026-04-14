import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/firebase/firebase_errors.dart';
import '../../../services/firebase/firestore_mappers.dart';
import '../../../services/firebase/firestore_paths.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  @override
  Future<UserModel?> restoreSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    try {
      return await _loadOrCreateUserDocument(fbUser);
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  Future<UserModel> _loadOrCreateUserDocument(
    User fbUser, {
    String? signInEmailFallback,
  }) async {
    final uid = fbUser.uid;
    final snap = await _db.collection(FirestorePaths.users).doc(uid).get();
    if (snap.exists && snap.data() != null) {
      final data = Map<String, dynamic>.from(snap.data()!);
      data['id'] = uid;
      return UserModel.fromMap(data);
    }
    final emailResolved =
        fbUser.email?.trim().toLowerCase() ??
        signInEmailFallback?.trim().toLowerCase() ??
        '';
    final created = fbUser.metadata.creationTime ?? DateTime.now();
    final user = UserModel(
      id: uid,
      email: emailResolved,
      createdAt: created,
      selectedPlan: null,
      subscriptionStatus: SubscriptionStatus.none,
    );
    await _db
        .collection(FirestorePaths.users)
        .doc(uid)
        .set(FirestoreMappers.userWrite(user), SetOptions(merge: true));
    return user;
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return await _loadOrCreateUserDocument(
        cred.user!,
        signInEmailFallback: email,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      final now = DateTime.now();
      final user = UserModel(
        id: uid,
        email: email.trim().toLowerCase(),
        createdAt: now,
        selectedPlan: null,
        subscriptionStatus: SubscriptionStatus.none,
      );
      await _db
          .collection(FirestorePaths.users)
          .doc(uid)
          .set(FirestoreMappers.userWrite(user));
      return user;
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    } catch (e) {
      throw Exception(FirebaseErrors.firestoreMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    }
  }
}
