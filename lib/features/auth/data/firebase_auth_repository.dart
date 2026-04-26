import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/config/auth_action_config.dart';
import '../../../core/config/social_auth_config.dart';
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
      throw Exception('Connexion impossible: $e');
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
      throw Exception('Inscription impossible: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    if (!SocialAuthConfig.googleSignInConfigured) {
      throw Exception(
        'Google Sign-In : ajoutez GOOGLE_SIGN_IN_SERVER_CLIENT_ID '
        '(ID client OAuth Web Firebase) dans dart_defines.json.',
      );
    }
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Google n’a pas renvoyé d’idToken. Vérifiez le SHA-1/256 Android '
          'et le client OAuth dans la console Google Cloud / Firebase.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final cred = await _auth.signInWithCredential(credential);
      return await _loadOrCreateUserDocument(
        cred.user!,
        signInEmailFallback: account.email,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    if (!await SignInWithApple.isAvailable()) {
      throw Exception(
        'Connexion Apple indisponible sur cet appareil ou navigateur.',
      );
    }
    try {
      WebAuthenticationOptions? webOpts;
      if (kIsWeb) {
        if (!SocialAuthConfig.appleWebConfigured) {
          throw Exception(
            'Apple sur le web : renseignez APPLE_SIGN_IN_SERVICE_ID et '
            'APPLE_SIGN_IN_REDIRECT_URI (console Apple + Firebase).',
          );
        }
        webOpts = WebAuthenticationOptions(
          clientId: SocialAuthConfig.appleServiceId,
          redirectUri: Uri.parse(SocialAuthConfig.appleRedirectUri),
        );
      }

      final rawNonce = generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
        webAuthenticationOptions: webOpts,
      );

      final oauth = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );
      final cred = await _auth.signInWithCredential(oauth);
      final email = appleCredential.email ?? cred.user?.email;
      return await _loadOrCreateUserDocument(
        cred.user!,
        signInEmailFallback: email,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  @override
  Future<UserModel> signInWithFacebook() async {
    if (!kIsWeb) {
      throw Exception(
        'Facebook : sur mobile, il faut configurer le SDK Meta '
        '(hors périmètre actuel). Utilisez le web ou Google / Apple.',
      );
    }
    try {
      final cred = await _auth.signInWithPopup(FacebookAuthProvider());
      return await _loadOrCreateUserDocument(
        cred.user!,
        signInEmailFallback: cred.user?.email,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (SocialAuthConfig.googleSignInConfigured) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw Exception('Email requis');
    }
    try {
      final action = AuthActionConfig.passwordResetActionCodeSettings();
      if (action != null) {
        await _auth.sendPasswordResetEmail(
          email: normalized,
          actionCodeSettings: action,
        );
      } else {
        await _auth.sendPasswordResetEmail(email: normalized);
      }
      if (kDebugMode) {
        debugPrint(
          'elunai.auth: password reset requested for $normalized '
          '(actionUrl=${AuthActionConfig.passwordResetContinueUrl.isEmpty ? "default" : "custom"})',
        );
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(FirebaseErrors.authMessage(e));
    }
  }
}
