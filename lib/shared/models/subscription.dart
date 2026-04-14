import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums/renewal_type.dart';
import 'enums/subscription_status.dart';

class Subscription extends Equatable {
  const Subscription({
    required this.userId,
    required this.planId,
    required this.status,
    required this.startedAt,
    this.endsAt,
    required this.renewalType,
  });

  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startedAt;
  final DateTime? endsAt;
  final RenewalType renewalType;

  Subscription copyWith({
    String? userId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? startedAt,
    DateTime? endsAt,
    RenewalType? renewalType,
  }) {
    return Subscription(
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      renewalType: renewalType ?? this.renewalType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status.wireValue,
      'startedAt': startedAt.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'renewalType': renewalType.wireValue,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      userId: map['userId'] as String,
      planId: map['planId'] as String,
      status: SubscriptionStatusX.parse(map['status'] as String?),
      startedAt: _readDate(map['startedAt']),
      endsAt: map['endsAt'] != null ? _readDate(map['endsAt']) : null,
      renewalType: RenewalTypeX.parse(map['renewalType'] as String?),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw FormatException('Unsupported date: $value');
  }

  @override
  List<Object?> get props => [
    userId,
    planId,
    status,
    startedAt,
    endsAt,
    renewalType,
  ];
}
