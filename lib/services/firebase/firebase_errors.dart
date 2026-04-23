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
    if (error is FirebaseException) {
      final code = error.code.trim();
      final msg = (error.message ?? '').trim();
      switch (code) {
        case 'permission-denied':
          return 'Acces refuse aux donnees (permission-denied).';
        case 'unavailable':
          return 'Service temporairement indisponible (unavailable).';
        case 'failed-precondition':
          return msg.isNotEmpty
              ? 'Firestore precondition: $msg'
              : 'Firestore precondition non satisfaite (failed-precondition).';
        case 'not-found':
          return 'Document/ressource introuvable (not-found).';
        default:
          if (msg.isNotEmpty) return 'Firestore [$code]: $msg';
          return 'Firestore [$code]';
      }
    }
    final s = error.toString();
    if (s.contains('permission-denied')) {
      return 'Acces refuse aux donnees (permission-denied).';
    }
    if (s.contains('unavailable')) {
      return 'Service temporairement indisponible (unavailable).';
    }
    if (s.contains('failed-precondition')) {
      return 'Firestore precondition non satisfaite (failed-precondition).';
    }
    return 'Erreur Firestore: $s';
  }
}
