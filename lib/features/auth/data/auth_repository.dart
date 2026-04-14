import '../../../shared/models/user_model.dart';

abstract class AuthRepository {
  /// Utilisateur Firebase déjà connecté (persisté) → charge le [UserModel] Firestore, ou `null`.
  Future<UserModel?> restoreSession();

  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({required String email, required String password});

  Future<void> signOut();
}
