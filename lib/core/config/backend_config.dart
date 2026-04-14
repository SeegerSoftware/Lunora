import 'runtime_env.dart';

/// Bascule data layer : `false` = mocks, `true` = Firebase (Auth + Firestore).
///
/// Ordre de priorité :
/// 1. `--dart-define=USE_FIREBASE=true` (compilation)
/// 2. Variable d’environnement système `USE_FIREBASE=true` (VM / desktop / Android / iOS)
///
/// Sur **web**, seul `dart-define` s’applique (pas de `Platform.environment` côté navigateur).
abstract final class BackendConfig {
  static bool get useFirebase {
    const fromDefine = bool.fromEnvironment(
      'USE_FIREBASE',
      defaultValue: false,
    );
    if (fromDefine) return true;
    return readRuntimeEnvFlag('USE_FIREBASE');
  }
}
