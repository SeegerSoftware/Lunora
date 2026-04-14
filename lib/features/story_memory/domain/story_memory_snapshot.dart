import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Mémoire légère associée à une histoire générée (une entrée par [storyId]).
class StoryMemorySnapshot extends Equatable {
  const StoryMemorySnapshot({
    required this.id,
    required this.childId,
    required this.userId,
    required this.storyId,
    this.seriesId,
    required this.dateKey,
    required this.summaryShort,
    required this.usedThemes,
    required this.usedPlaces,
    required this.usedCharacters,
    required this.emotionBeat,
    required this.lesson,
    required this.stateAfterStory,
    required this.createdAt,
  });

  final String id;
  final String childId;
  final String userId;
  final String storyId;
  final String? seriesId;
  final String dateKey;
  final String summaryShort;
  final List<String> usedThemes;
  final List<String> usedPlaces;
  final List<String> usedCharacters;
  final String emotionBeat;
  final String lesson;
  final String stateAfterStory;
  final DateTime createdAt;

  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'storyId': storyId,
      'seriesId': seriesId,
      'dateKey': dateKey,
      'summaryShort': summaryShort,
      'usedThemes': usedThemes,
      'usedPlaces': usedPlaces,
      'usedCharacters': usedCharacters,
      'emotionBeat': emotionBeat,
      'lesson': lesson,
      'stateAfterStory': stateAfterStory,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static StoryMemorySnapshot fromFirestore(String docId, Map<String, dynamic> m) {
    DateTime readTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return DateTime.now();
    }

    List<String> readList(dynamic v) {
      if (v is! List) return const [];
      return v.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }

    return StoryMemorySnapshot(
      id: (m['id'] ?? docId).toString(),
      childId: m['childId']?.toString() ?? '',
      userId: m['userId']?.toString() ?? '',
      storyId: m['storyId']?.toString() ?? docId,
      seriesId: m['seriesId']?.toString(),
      dateKey: m['dateKey']?.toString() ?? '',
      summaryShort: m['summaryShort']?.toString() ?? '',
      usedThemes: readList(m['usedThemes']),
      usedPlaces: readList(m['usedPlaces']),
      usedCharacters: readList(m['usedCharacters']),
      emotionBeat: m['emotionBeat']?.toString() ?? '',
      lesson: m['lesson']?.toString() ?? '',
      stateAfterStory: m['stateAfterStory']?.toString() ?? '',
      createdAt: readTs(m['createdAt']),
    );
  }

  @override
  List<Object?> get props => [
        id,
        childId,
        userId,
        storyId,
        seriesId,
        dateKey,
        summaryShort,
        usedThemes,
        usedPlaces,
        usedCharacters,
        emotionBeat,
        lesson,
        stateAfterStory,
        createdAt,
      ];
}
