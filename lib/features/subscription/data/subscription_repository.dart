import '../../../shared/models/subscription.dart';

abstract class SubscriptionRepository {
  Future<Subscription?> current(String userId);

  Future<void> clear();
}
