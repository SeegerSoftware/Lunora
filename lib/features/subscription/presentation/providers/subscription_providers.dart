import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/models/enums/story_plan.dart';
import '../../../../shared/models/subscription.dart';
import '../../../../shared/models/user_model.dart';

final subscriptionProvider =
    NotifierProvider<SubscriptionNotifier, Subscription?>(
      SubscriptionNotifier.new,
    );

class SubscriptionNotifier extends Notifier<Subscription?> {
  @override
  Subscription? build() => null;

  Future<void> refreshFromRepositoryFor(String userId) async {
    state = await ref.read(subscriptionRepositoryProvider).current(userId);
  }

  Future<Subscription> selectMockPlanFor({
    required UserModel user,
    required StoryPlan plan,
  }) async {
    final subscription = await ref
        .read(subscriptionRepositoryProvider)
        .selectMockPlan(user: user, plan: plan);
    state = subscription;
    return subscription;
  }

  void clear() {
    state = null;
  }
}
