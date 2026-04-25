/// Clé publique Stripe (`pk_…`) — [String.fromEnvironment] / CI / `--dart-define`.
abstract final class StripeConfig {
  static const String _publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get publishableKey => _publishableKey.trim();

  /// Prêt pour `flutter_stripe` / Stripe.js une fois la clé fournie.
  static bool get isPublishableKeyConfigured =>
      publishableKey.isNotEmpty && publishableKey.startsWith('pk_');
}
