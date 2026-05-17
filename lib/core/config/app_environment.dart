enum AppEnvironment { development, staging, production }

/// Voir `lib/core/config/mobile_api_config.dart` (USE_SERVER_API, ELUNAI_API_BASE_URL).
class AppConfig {
  const AppConfig({required this.environment});

  final AppEnvironment environment;

  static const AppConfig current = AppConfig(
    environment: AppEnvironment.development,
  );

}
