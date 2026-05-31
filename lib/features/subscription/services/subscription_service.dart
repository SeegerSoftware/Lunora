import '../../../shared/models/enums/subscription_plan.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_model.dart';

abstract final class SubscriptionService {
  static SubscriptionPlan effectivePlan({
    required UserModel user,
    Subscription? subscription,
  }) {
    return subscription?.plan ?? user.subscriptionPlan;
  }

  static String childrenLimitMessage(SubscriptionPlan plan) {
    return plan == SubscriptionPlan.solo
        ? 'Vous avez atteint la limite de votre abonnement. Passez a Elunai Famille pour ajouter davantage d’enfants.'
        : 'Vous avez atteint la limite de votre abonnement.';
  }
}
