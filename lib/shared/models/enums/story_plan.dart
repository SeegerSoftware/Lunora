/// Plans d’abonnement indexés sur la durée moyenne d’histoire (MVP).
enum StoryPlan { minutes5, minutes10, minutes15 }

extension StoryPlanX on StoryPlan {
  int get targetStoryMinutes => switch (this) {
    StoryPlan.minutes5 => 5,
    StoryPlan.minutes10 => 10,
    StoryPlan.minutes15 => 15,
  };

  String get planId => switch (this) {
    StoryPlan.minutes5 => 'plan_5',
    StoryPlan.minutes10 => 'plan_10',
    StoryPlan.minutes15 => 'plan_15',
  };

  String get displayLabel => switch (this) {
    StoryPlan.minutes5 => 'Essentiel · 5 min',
    StoryPlan.minutes10 => 'Sérénité · 10 min',
    StoryPlan.minutes15 => 'Rituel · 15 min',
  };

  static StoryPlan fromPlanId(String? raw) {
    return StoryPlan.values.firstWhere(
      (e) => e.planId == raw,
      orElse: () => StoryPlan.minutes10,
    );
  }
}
