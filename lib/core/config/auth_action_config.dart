import 'package:firebase_auth/firebase_auth.dart';

/// URLs d’action Firebase (réinitialisation mot de passe, etc.).
///
/// Définir [PASSWORD_RESET_CONTINUE_URL] dans `dart_defines.json` :
/// une page **https** déjà ajoutée dans la console Firebase
/// (Authentication → Paramètres → Domaines autorisés), par ex.
/// `https://ton-domaine.ch/welcome` ou l’URL hébergée Firebase Hosting.
///
/// Sans URL, Firebase envoie quand même l’e-mail par défaut ; avec URL,
/// le lien « Continuer » mène à ton domaine (souvent meilleure délivrabilité).
abstract final class AuthActionConfig {
  static const String passwordResetContinueUrl = String.fromEnvironment(
    'PASSWORD_RESET_CONTINUE_URL',
    defaultValue: '',
  );

  static const String androidPackageName = String.fromEnvironment(
    'ANDROID_PACKAGE_NAME',
    defaultValue: 'lunora.v00',
  );

  static const String iosBundleId = String.fromEnvironment(
    'IOS_BUNDLE_ID',
    defaultValue: 'com.lunora.lunora',
  );

  /// Réglages pour `sendPasswordResetEmail` (mobile + lien navigateur).
  static ActionCodeSettings? passwordResetActionCodeSettings() {
    final url = passwordResetContinueUrl.trim();
    if (url.isEmpty) return null;
    return ActionCodeSettings(
      url: url,
      handleCodeInApp: false,
      androidPackageName: androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: iosBundleId,
    );
  }
}
