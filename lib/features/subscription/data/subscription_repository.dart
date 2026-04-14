import '../../../shared/models/enums/story_plan.dart';
import '../../../shared/models/subscription.dart';
import '../../../shared/models/user_model.dart';

abstract class SubscriptionRepository {
  Future<Subscription?> current(String userId);

  Future<Subscription> selectMockPlan({
    required UserModel user,
    required StoryPlan plan,
  });

  Future<void> clear();
}
