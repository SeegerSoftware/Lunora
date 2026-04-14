import '../../../services/mock/lunora_mock_store.dart';
import '../../../shared/models/enums/renewal_type.dart';
import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/models/enums/subscription_status.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_model.dart';
import 'subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository({required LunoraMockStore store}) : _store = store;

  final LunoraMockStore _store;

  @override
  Future<void> clear() async {
    _store.subscription = null;
  }

  @override
  Future<Subscription?> current(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final sub = _store.subscription;
    if (sub == null) return null;
    if (sub.userId != userId) return null;
    return sub;
  }

  @override
  Future<Subscription> selectMockPlan({
    required UserModel user,
    required StoryPlan plan,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final now = DateTime.now();
    final sub = Subscription(
      userId: user.id,
      planId: plan.planId,
      status: SubscriptionStatus.active,
      startedAt: now,
      endsAt: now.add(const Duration(days: 30)),
      renewalType: RenewalType.monthly,
    );
    _store.subscription = sub;
    return sub;
  }
}
