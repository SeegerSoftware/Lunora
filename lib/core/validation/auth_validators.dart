import '../constants/profile_limits.dart';

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
    if (v.length < ProfileLimits.minPasswordLength) {
      return 'Mot de passe : ${ProfileLimits.minPasswordLength} caractères minimum';
    }
    return null;
  }
}
