enum SubscriptionPlan { solo, family }

extension SubscriptionPlanX on SubscriptionPlan {
  String get wireValue => name;

  String get planId => switch (this) {
    SubscriptionPlan.solo => 'plan_solo',
    SubscriptionPlan.family => 'plan_family',
  };

  String get displayName => switch (this) {
    SubscriptionPlan.solo => 'Elunai Solo',
    SubscriptionPlan.family => 'Elunai Famille',
  };

  String get priceLabel => switch (this) {
    SubscriptionPlan.solo => 'CHF 4.99 / mois',
    SubscriptionPlan.family => 'CHF 8.99 / mois',
  };

  int get maxChildren => switch (this) {
    SubscriptionPlan.solo => 1,
    SubscriptionPlan.family => 4,
  };

  int get dailyStoriesPerChild => 1;

  bool get hasAudio => false;

  bool canAddChild(int currentChildrenCount) =>
      currentChildrenCount < maxChildren;

  bool hasReachedChildrenLimit(int currentChildrenCount) =>
      !canAddChild(currentChildrenCount);

  List<String> get keyBenefits => [
    '$maxChildren enfant${maxChildren > 1 ? 's' : ''} maximum',
    '$dailyStoriesPerChild histoire personnalisee par jour par enfant',
    'Lecture texte et historique illimite',
  ];

  static SubscriptionPlan fromPlanId(String? raw) {
    return switch (raw) {
      'plan_family' || 'family' => SubscriptionPlan.family,
      _ => SubscriptionPlan.solo,
    };
  }

  static SubscriptionPlan fromWireValue(String? raw) {
    return raw == SubscriptionPlan.family.wireValue
        ? SubscriptionPlan.family
        : SubscriptionPlan.solo;
  }
}
