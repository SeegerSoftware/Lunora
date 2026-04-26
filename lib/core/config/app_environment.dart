enum AppEnvironment { development, staging, production }

/// Voir `lib/core/config/ai_generation_config.dart` (USE_REAL_AI, OPENAI_API_KEY, …).
class AppConfig {
  const AppConfig({required this.environment});

  final AppEnvironment environment;

  static const AppConfig current = AppConfig(
    environment: AppEnvironment.development,
  );

}
