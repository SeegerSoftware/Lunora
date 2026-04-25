import '../../../shared/models/user_model.dart';

abstract class AuthRepository {
  /// Utilisateur Firebase déjà connecté (persisté) → charge le [UserModel] Firestore, ou `null`.
  Future<UserModel?> restoreSession();

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({required String email, required String password});

  Future<UserModel> signInWithGoogle();

  /// iOS / macOS / Android / Web si [SignInWithApple.isAvailable].
  Future<UserModel> signInWithApple();

  /// Web : popup Firebase. Mobile : nécessite le SDK Meta (non inclus).
  Future<UserModel> signInWithFacebook();

  Future<void> signOut();
}
