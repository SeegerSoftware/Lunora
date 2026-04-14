import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Univers narratif persistant pour un enfant (un document actif par enfant).
class StoryWorld extends Equatable {
  const StoryWorld({
    required this.id,
    required this.childId,
    required this.userId,
    required this.worldName,
    required this.mainCompanion,
    required this.magicItem,
    required this.coreGoal,
    required this.recurringPlaces,
    required this.worldTone,
    required this.currentState,
    required this.currentArc,
    required this.recentlyUsedElements,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String childId;
  final String userId;
  final String worldName;
  final String mainCompanion;
  final String magicItem;
  final String coreGoal;
  final List<String> recurringPlaces;
  final String worldTone;
  final String currentState;
  final String currentArc;
  final List<String> recentlyUsedElements;
  final DateTime createdAt;
  final DateTime updatedAt;

  StoryWorld copyWith({
    String? id,
    String? childId,
    String? userId,
    String? worldName,
    String? mainCompanion,
    String? magicItem,
    String? coreGoal,
    List<String>? recurringPlaces,
    String? worldTone,
    String? currentState,
    String? currentArc,
    List<String>? recentlyUsedElements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StoryWorld(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      worldName: worldName ?? this.worldName,
      mainCompanion: mainCompanion ?? this.mainCompanion,
      magicItem: magicItem ?? this.magicItem,
      coreGoal: coreGoal ?? this.coreGoal,
      recurringPlaces: recurringPlaces ?? this.recurringPlaces,
      worldTone: worldTone ?? this.worldTone,
      currentState: currentState ?? this.currentState,
      currentArc: currentArc ?? this.currentArc,
      recentlyUsedElements: recentlyUsedElements ?? this.recentlyUsedElements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'worldName': worldName,
      'mainCompanion': mainCompanion,
      'magicItem': magicItem,
      'coreGoal': coreGoal,
      'recurringPlaces': recurringPlaces,
      'worldTone': worldTone,
      'currentState': currentState,
      'currentArc': currentArc,
      'recentlyUsedElements': recentlyUsedElements,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static StoryWorld fromFirestore(String docId, Map<String, dynamic> m) {
    DateTime readTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    List<String> readList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    return StoryWorld(
      id: (m['id'] ?? docId).toString(),
      childId: (m['childId'] ?? docId).toString(),
      userId: m['userId']?.toString() ?? '',
      worldName: m['worldName']?.toString() ?? 'Monde doux',
      mainCompanion: m['mainCompanion']?.toString() ?? '',
      magicItem: m['magicItem']?.toString() ?? '',
      coreGoal: m['coreGoal']?.toString() ?? '',
      recurringPlaces: readList(m['recurringPlaces']),
      worldTone: m['worldTone']?.toString() ?? '',
      currentState: m['currentState']?.toString() ?? '',
      currentArc: m['currentArc']?.toString() ?? '',
      recentlyUsedElements: readList(m['recentlyUsedElements']),
      createdAt: readTs(m['createdAt']),
      updatedAt: readTs(m['updatedAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        childId,
        userId,
        worldName,
        mainCompanion,
        magicItem,
        coreGoal,
        recurringPlaces,
        worldTone,
        currentState,
        currentArc,
        recentlyUsedElements,
        createdAt,
        updatedAt,
      ];
}
