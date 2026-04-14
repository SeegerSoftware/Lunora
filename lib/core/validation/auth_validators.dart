import '../../services/mock/mock_data.dart';

abstract final class AuthValidators {
  static String? emailError(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return 'Email requis';
    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(v)) return 'Email invalide';
    return null;
  }

  static String? passwordError(String? raw) {
    final v = raw ?? '';
    if (v.isEmpty) return 'Mot de passe requis';
    if (v.length < MockData.minPasswordLength) {
      return 'Mot de passe : ${MockData.minPasswordLength} caractères minimum';
    }
    return null;
  }
}
