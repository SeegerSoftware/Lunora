import 'package:elunai_v00/shared/models/enums/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solo limits profiles to one child', () {
    expect(SubscriptionPlan.solo.displayName, 'Elunai Solo');
    expect(SubscriptionPlan.solo.maxChildren, 1);
    expect(SubscriptionPlan.solo.canAddChild(0), isTrue);
    expect(SubscriptionPlan.solo.hasReachedChildrenLimit(1), isTrue);
    expect(SubscriptionPlan.solo.hasAudio, isFalse);
  });

  test('family allows four children and keeps one daily story per child', () {
    expect(SubscriptionPlan.family.displayName, 'Elunai Famille');
    expect(SubscriptionPlan.family.maxChildren, 4);
    expect(SubscriptionPlan.family.dailyStoriesPerChild, 1);
    expect(SubscriptionPlan.family.canAddChild(3), isTrue);
    expect(SubscriptionPlan.family.canAddChild(4), isFalse);
  });

  test('legacy plan identifiers migrate softly to solo', () {
    expect(SubscriptionPlanX.fromPlanId('plan_elunai'), SubscriptionPlan.solo);
    expect(SubscriptionPlanX.fromPlanId(null), SubscriptionPlan.solo);
    expect(
      SubscriptionPlanX.fromPlanId('plan_family'),
      SubscriptionPlan.family,
    );
  });
}
