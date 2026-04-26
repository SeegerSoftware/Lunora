import '../../shared/models/enums/story_plan.dart';

/// Clé publique Stripe (`pk_…`) — [String.fromEnvironment] / CI / `--dart-define`.
abstract final class StripeConfig {
  static const String _publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static String get publishableKey => _publishableKey.trim();

  static const String _checkoutUrl = String.fromEnvironment(
    'STRIPE_CHECKOUT_URL',
    defaultValue: '',
  );
  /// Compat : anciennes configs par durée.
  static const String _checkoutUrlLegacy10 = String.fromEnvironment(
    'STRIPE_CHECKOUT_URL_PLAN_10',
    defaultValue: '',
  );

  /// Prêt pour `flutter_stripe` / Stripe.js une fois la clé fournie.
  static bool get isPublishableKeyConfigured =>
      publishableKey.isNotEmpty && publishableKey.startsWith('pk_');

  static String? checkoutUrlForPlan(StoryPlan plan) {
    final primary = _checkoutUrl.trim();
    final legacy = _checkoutUrlLegacy10.trim();
    final url = primary.isNotEmpty ? primary : legacy;
    if (url.isEmpty) return null;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return null;
    return url;
  }
}
