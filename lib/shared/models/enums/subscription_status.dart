enum SubscriptionStatus { none, active, grace, canceled }

extension SubscriptionStatusX on SubscriptionStatus {
  String get wireValue => name;

  static SubscriptionStatus parse(String? raw) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => SubscriptionStatus.none,
    );
  }
}
