import 'runtime_env.dart';

/// Configuration génération IA.
///
/// **Où mettre la clé OpenAI**
/// 1. Fichier **`dart_defines.json`** à la racine du projet (copie `dart_defines.example.json`),
///    puis lancer avec : `flutter run --dart-define-from-file=dart_defines.json`
///    (ou F5 avec la config VS Code « Lunora »).
/// 2. **Variables d’environnement** sur ta machine : `OPENAI_API_KEY`, `USE_REAL_AI`, etc.
///    Ensuite un simple `flutter run` suffit (hors web).
///
/// Ne jamais committer `dart_defines.json` (déjà dans `.gitignore`).
abstract final class AiGenerationConfig {
  static bool get useRealAi {
    const fromDefine = bool.fromEnvironment(
      'USE_REAL_AI',
      defaultValue: false,
    );
    if (fromDefine) return true;
    return readRuntimeEnvFlag('USE_REAL_AI');
  }

  static String get openaiApiKey {
    const fromDefine = String.fromEnvironment(
      'OPENAI_API_KEY',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    return readRuntimeEnv('OPENAI_API_KEY')?.trim() ?? '';
  }

  static String get openaiModel {
    const fromDefine = String.fromEnvironment(
      'OPENAI_MODEL',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    final env = readRuntimeEnv('OPENAI_MODEL')?.trim();
    if (env != null && env.isNotEmpty) return env;
    return 'gpt-4o';
  }

  /// Modèle utilisé uniquement en secours qualité (coût plus élevé).
  static String get openaiModelPremium {
    const fromDefine = String.fromEnvironment(
      'OPENAI_MODEL_PREMIUM',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) return fromDefine.trim();
    final env = readRuntimeEnv('OPENAI_MODEL_PREMIUM')?.trim();
    if (env != null && env.isNotEmpty) return env;
    return 'gpt-4o';
  }

  static String get openaiBaseUrl {
    const fromDefine = String.fromEnvironment(
      'OPENAI_BASE_URL',
      defaultValue: '',
    );
    if (fromDefine.trim().isNotEmpty) {
      return fromDefine.trim().replaceAll(RegExp(r'/$'), '');
    }
    final env = readRuntimeEnv('OPENAI_BASE_URL')?.trim();
    if (env != null && env.isNotEmpty) {
      return env.replaceAll(RegExp(r'/$'), '');
    }
    return 'https://api.openai.com';
  }

  static int get _timeoutSeconds {
    const fromDefine = int.fromEnvironment(
      'OPENAI_TIMEOUT_SECONDS',
      defaultValue: -1,
    );
    if (fromDefine >= 30) return fromDefine;
    final raw = readRuntimeEnv('OPENAI_TIMEOUT_SECONDS')?.trim();
    final parsed = int.tryParse(raw ?? '');
    if (parsed != null && parsed >= 30) return parsed;
    return 120;
  }

  static Duration get requestTimeout =>
      Duration(seconds: _timeoutSeconds.clamp(30, 300));

  static bool get hasOpenAiKey => openaiApiKey.trim().isNotEmpty;

  static bool get canUseRemoteAi => useRealAi && hasOpenAiKey;

  /// Affiche system + user dans la console (Flutter : terminal / debug).
  /// À n’activer qu’en local : le prompt contient des données enfant.
  static bool get logOpenAiPrompts {
    const fromDefine = bool.fromEnvironment(
      'OPENAI_LOG_PROMPTS',
      defaultValue: false,
    );
    if (fromDefine) return true;
    return readRuntimeEnvFlag('OPENAI_LOG_PROMPTS');
  }

  /// Log une ligne par appel API (modèle utilisé). Désactivé par défaut hors debug
  /// (voir `OpenAiChatClient` : en debug Flutter, actif sans config).
  static bool get logOpenAiCalls {
    const fromDefine = bool.fromEnvironment(
      'OPENAI_LOG_CALLS',
      defaultValue: false,
    );
    if (fromDefine) return true;
    return readRuntimeEnvFlag('OPENAI_LOG_CALLS');
  }
}
