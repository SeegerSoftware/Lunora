import 'package:shared_preferences/shared_preferences.dart';

abstract final class SecurityPreferences {
  static const String _biometricLockEnabledKey =
      'security.biometric_lock_enabled';

  /// Activé par défaut sur mobile quand la biométrie est disponible.
  static Future<bool> isBiometricLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricLockEnabledKey) ?? true;
  }

  static Future<void> setBiometricLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricLockEnabledKey, enabled);
  }
}
