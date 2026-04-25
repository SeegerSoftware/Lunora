import 'runtime_env.dart';

/// Identifiants OAuth (dart-define ou variables d’environnement).
///
/// **Google** : dans la console Firebase → Authentification → Méthode Google,
/// récupère l’**ID client OAuth Web** (souvent aussi utilisé comme
/// `serverClientId` côté Android pour obtenir un `idToken` Firebase).
abstract final class SocialAuthConfig {
  /// Client OAuth « Web » Firebase (souvent `….apps.googleusercontent.com`).
  static String get googleServerClientId {
    const fromDefine = String.fromEnvironment(
      'GOOGLE_SIGN_IN_SERVER_CLIENT_ID',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return readRuntimeEnv('GOOGLE_SIGN_IN_SERVER_CLIENT_ID')?.trim() ?? '';
  }

  /// Sur le web uniquement : ID client OAuth de type « Application Web ».
  static String get googleWebClientId {
    const fromDefine = String.fromEnvironment(
      'GOOGLE_SIGN_IN_WEB_CLIENT_ID',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    final env = readRuntimeEnv('GOOGLE_SIGN_IN_WEB_CLIENT_ID')?.trim();
    if (env != null && env.isNotEmpty) return env;
    return googleServerClientId;
  }

  static bool get googleSignInConfigured => googleServerClientId.isNotEmpty;

  /// Service ID Apple (web / Android Sign in with Apple).
  static String get appleServiceId {
    const fromDefine = String.fromEnvironment(
      'APPLE_SIGN_IN_SERVICE_ID',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return readRuntimeEnv('APPLE_SIGN_IN_SERVICE_ID')?.trim() ?? '';
  }

  /// URL de redirection enregistrée chez Apple (ex. `https://xxx.firebaseapp.com/__/auth/handler`).
  static String get appleRedirectUri {
    const fromDefine = String.fromEnvironment(
      'APPLE_SIGN_IN_REDIRECT_URI',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return readRuntimeEnv('APPLE_SIGN_IN_REDIRECT_URI')?.trim() ?? '';
  }

  static bool get appleWebConfigured =>
      appleServiceId.isNotEmpty && appleRedirectUri.isNotEmpty;
}
