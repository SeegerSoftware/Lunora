import 'package:firebase_auth/firebase_auth.dart';

abstract final class FirebaseErrors {
  static String authMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'operation-not-allowed':
          return 'Provider Email/Password non active dans Firebase Auth.';
        case 'invalid-api-key':
          return 'Cle API Firebase invalide pour ce projet.';
        case 'app-not-authorized':
          return 'Application/domaine non autorise dans Firebase.';
        case 'internal-error':
          return 'Erreur interne Firebase Auth (verifier configuration projet/auth).';
        case 'too-many-requests':
          return 'Trop de tentatives. Reessaie dans quelques minutes.';
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
        case 'account-exists-with-different-credential':
          return 'Ce compte existe déjà avec une autre méthode de connexion '
              '(Google, Apple, etc.). Utilisez la même méthode qu’à l’inscription.';
        case 'network-request-failed':
          return 'Problème de connexion réseau.';
        default:
          final msg = error.message?.trim() ?? '';
          if (msg.isNotEmpty && msg.toLowerCase() != 'error') return msg;
          return 'Authentification impossible [${error.code}].';
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
