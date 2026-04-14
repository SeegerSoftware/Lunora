import 'package:firebase_auth/firebase_auth.dart';

abstract final class FirebaseErrors {
  static String authMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Adresse email invalide.';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'user-not-found':
          return 'Aucun compte pour cet email.';
        case 'wrong-password':
          return 'Mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cet email est déjà utilisé.';
        case 'weak-password':
          return 'Mot de passe trop faible.';
        case 'invalid-credential':
          return 'Identifiants incorrects.';
        case 'network-request-failed':
          return 'Problème de connexion réseau.';
        default:
          return error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : 'Authentification impossible.';
      }
    }
    return 'Une erreur est survenue.';
  }

  static String firestoreMessage(Object error) {
    final s = error.toString();
    if (s.contains('permission-denied')) {
      return 'Accès refusé aux données.';
    }
    if (s.contains('unavailable')) {
      return 'Service temporairement indisponible.';
    }
    return 'Erreur lors de la lecture ou de l’enregistrement.';
  }
}
