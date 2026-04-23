import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/backend_config.dart';
import '../../../../core/di/providers.dart';
import '../../../../shared/models/enums/subscription_status.dart';
import '../../../../shared/models/user_model.dart';
import '../../../child_profile/presentation/providers/child_profile_providers.dart';
import '../../../subscription/presentation/providers/subscription_providers.dart';

final authSessionProvider = NotifierProvider<AuthSessionNotifier, UserModel?>(
  AuthSessionNotifier.new,
);

/// Garde la session Riverpod alignée sur Firebase Auth (persistée au redémarrage).
final firebaseAuthSyncProvider = Provider<void>((ref) {
  if (!BackendConfig.useFirebase) return;

  final sub = FirebaseAuth.instance.authStateChanges().listen((
    User? fbUser,
  ) async {
    try {
      if (fbUser == null) {
        if (ref.read(authSessionProvider) != null) {
          ref.read(authSessionProvider.notifier).syncSignedOutFromFirebase();
        }
        ref.read(childProfileProvider.notifier).clear();
        ref.read(subscriptionProvider.notifier).clear();
        return;
      }

      final user = await ref.read(authRepositoryProvider).restoreSession();
      if (user == null) return;

      await ref
          .read(authSessionProvider.notifier)
          .hydrateFromRestoredUser(user);
    } catch (e, st) {
      debugPrint('firebaseAuthSync: $e\n$st');
    }
  });

  ref.onDispose(sub.cancel);
});

class AuthSessionNotifier extends Notifier<UserModel?> {
  @override
  UserModel? build() => null;

  /// Firebase a déjà terminé la déconnexion (ex. autre onglet) : vider l’état local sans rappeler [AuthRepository.signOut].
  void syncSignedOutFromFirebase() {
    state = null;
    ref.read(childProfileProvider.notifier).clear();
    ref.read(subscriptionProvider.notifier).clear();
  }

  Future<void> hydrateFromRestoredUser(UserModel user) async {
    // Charger profil + abonnement avant d’exposer la session, sinon le routeur
    // envoie vers /setup-child alors que le profil arrive un instant après.
    await _afterAuthChanged(user.id);
    state = user;
  }

  Future<void> signIn({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signIn(email: email, password: password);
    await _afterAuthChanged(user.id);
    state = user;
  }

  Future<void> signUp({required String email, required String password}) async {
    final user = await ref
        .read(authRepositoryProvider)
        .signUp(email: email, password: password);
    await _afterAuthChanged(user.id);
    state = user;
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    syncSignedOutFromFirebase();
  }

  void applyPlanSelection({
    required String planId,
    required SubscriptionStatus status,
  }) {
    final user = state;
    if (user == null) return;
    state = user.copyWith(selectedPlan: planId, subscriptionStatus: status);
  }

  Future<void> _afterAuthChanged(String userId) async {
    await ref
        .read(childProfileProvider.notifier)
        .reloadFromRepositoryFor(userId);
    await ref
        .read(subscriptionProvider.notifier)
        .refreshFromRepositoryFor(userId);
  }
}
