/// Abonnement unique (MVP) — durée cible de lecture ~10 min.
enum StoryPlan { elunai }

extension StoryPlanX on StoryPlan {
  int get targetStoryMinutes => 10;

  String get planId => 'plan_elunai';

  String get displayLabel => 'Elunai — histoires du soir';

  /// Prix public : 5,99 CHF / mois.
  int get monthlyPriceCents => 599;

  String get monthlyPriceLabel {
    final chf = monthlyPriceCents / 100;
    return 'CHF ${chf.toStringAsFixed(2)} / mois';
  }

  String get marketingTag => 'Offre unique';

  List<String> get keyBenefits => const [
        'Histoires personnalisées pour le coucher',
        'Adaptation par âge et profil enfant',
        'Lecture apaisante et mode liseuse dédié',
      ];

  static StoryPlan fromPlanId(String? raw) {
    if (raw == null || raw.isEmpty) return StoryPlan.elunai;
    for (final p in StoryPlan.values) {
      if (p.planId == raw) return p;
    }
    // Anciens identifiants → offre unique actuelle
    if (raw == 'plan_5' || raw == 'plan_10' || raw == 'plan_15') {
      return StoryPlan.elunai;
    }
    return StoryPlan.elunai;
  }
}
