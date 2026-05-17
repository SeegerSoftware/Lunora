import 'runtime_env.dart';

/// Configuration de l'API backend Elunai (serveur applicatif).
abstract final class MobileApiConfig {
  static bool get useServerApi {
    const fromDefine = bool.fromEnvironment(
      'USE_SERVER_API',
      defaultValue: false,
    );
    if (fromDefine) return true;
    return readRuntimeEnvFlag('USE_SERVER_API');
  }

  static String get baseUrl {
    const fromDefine = String.fromEnvironment(
      'ELUNAI_API_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim().replaceAll(RegExp(r'/$'), '');
    }
    final env = readRuntimeEnv('ELUNAI_API_BASE_URL')?.trim();
    if (env != null && env.isNotEmpty) {
      return env.replaceAll(RegExp(r'/$'), '');
    }
    return '';
  }

  static bool get isConfigured => useServerApi && baseUrl.isNotEmpty;

  static Duration get requestTimeout {
    const fromDefine = int.fromEnvironment(
      'ELUNAI_API_TIMEOUT_SECONDS',
      defaultValue: 20,
    );
    final raw = readRuntimeEnv('ELUNAI_API_TIMEOUT_SECONDS')?.trim();
    final env = int.tryParse(raw ?? '');
    final seconds = env ?? fromDefine;
    return Duration(seconds: seconds.clamp(10, 120));
  }
}
