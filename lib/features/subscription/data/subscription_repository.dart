import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_model.dart';

abstract class SubscriptionRepository {
  Future<Subscription?> current(String userId);

  /// Active un abonnement de test (sans passerelle de paiement) — réservé au dev / QA.
  Future<Subscription> activateTestPlan({
    required UserModel user,
    required StoryPlan plan,
  });

  Future<void> clear();
}
