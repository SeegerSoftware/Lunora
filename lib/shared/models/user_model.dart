import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums/story_plan.dart';
import 'enums/subscription_status.dart';

class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.email,
    required this.createdAt,
    this.selectedPlan,
    required this.subscriptionStatus,
    this.isAdmin = false,
  });

  final String id;
  final String email;
  final DateTime createdAt;

  /// Identifiant de plan (ex. `plan_10`) — aligné sur `StoryPlan.planId`.
  final String? selectedPlan;
  final SubscriptionStatus subscriptionStatus;

  /// Réservé au build / console Firestore ; ne pas exposer aux parents dans l’UI normale.
  final bool isAdmin;

  StoryPlan? get selectedStoryPlan {
    final id = selectedPlan;
    if (id == null) return null;
    for (final candidate in StoryPlan.values) {
      if (candidate.planId == id) return candidate;
    }
    return null;
  }

  UserModel copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    String? selectedPlan,
    SubscriptionStatus? subscriptionStatus,
    bool? isAdmin,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'selectedPlan': selectedPlan,
      'subscriptionStatus': subscriptionStatus.wireValue,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      createdAt: _readDate(map['createdAt']),
      selectedPlan: map['selectedPlan'] as String?,
      subscriptionStatus: SubscriptionStatusX.parse(
        map['subscriptionStatus'] as String?,
      ),
      isAdmin: map['isAdmin'] == true,
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw FormatException('Unsupported createdAt: $value');
  }

  @override
  List<Object?> get props => [
    id,
    email,
    createdAt,
    selectedPlan,
    subscriptionStatus,
    isAdmin,
  ];
}
