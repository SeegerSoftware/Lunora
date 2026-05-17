import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../shared/models/subscription.dart';

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

  void clear() {
    state = null;
  }
}
