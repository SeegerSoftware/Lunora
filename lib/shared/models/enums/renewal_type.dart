enum RenewalType { monthly, yearly, none }

extension RenewalTypeX on RenewalType {
  String get wireValue => name;

  static RenewalType parse(String? raw) {
    return RenewalType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RenewalType.none,
    );
  }
}
