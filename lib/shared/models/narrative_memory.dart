import 'package:equatable/equatable.dart';

class NarrativeRelation extends Equatable {
  const NarrativeRelation({
    required this.name,
    required this.relationType,
    required this.sinceChapter,
  });

  final String name;
  final String relationType;
  final int sinceChapter;

  factory NarrativeRelation.fromMap(Map<String, dynamic> map) =>
      NarrativeRelation(
        name: map['name']?.toString() ?? '',
        relationType: map['relationType']?.toString() ?? '',
        sinceChapter: (map['sinceChapter'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
    'name': name,
    'relationType': relationType,
    'sinceChapter': sinceChapter,
  };

  @override
  List<Object?> get props => [name, relationType, sinceChapter];
}

class OpenMystery extends Equatable {
  const OpenMystery({
    required this.question,
    required this.openedAtChapter,
    required this.mustResolveBeforeChapter,
    this.status = 'open',
  });

  final String question;
  final int openedAtChapter;
  final int mustResolveBeforeChapter;
  final String status;

  factory OpenMystery.fromMap(Map<String, dynamic> map) => OpenMystery(
    question: map['question']?.toString() ?? '',
    openedAtChapter: (map['openedAtChapter'] as num?)?.toInt() ?? 1,
    mustResolveBeforeChapter:
        (map['mustResolveBeforeChapter'] as num?)?.toInt() ?? 1,
    status: map['status']?.toString() ?? 'open',
  );

  Map<String, dynamic> toMap() => {
    'question': question,
    'openedAtChapter': openedAtChapter,
    'mustResolveBeforeChapter': mustResolveBeforeChapter,
    'status': status,
  };

  @override
  List<Object?> get props => [
    question,
    openedAtChapter,
    mustResolveBeforeChapter,
    status,
  ];
}

class NarrativeObject extends Equatable {
  const NarrativeObject({
    required this.name,
    required this.importance,
    required this.firstSeenChapter,
    required this.lastSeenChapter,
  });

  final String name;
  final String importance;
  final int firstSeenChapter;
  final int lastSeenChapter;

  factory NarrativeObject.fromMap(Map<String, dynamic> map) => NarrativeObject(
    name: map['name']?.toString() ?? '',
    importance: map['importance']?.toString() ?? 'supporting',
    firstSeenChapter: (map['firstSeenChapter'] as num?)?.toInt() ?? 1,
    lastSeenChapter: (map['lastSeenChapter'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'importance': importance,
    'firstSeenChapter': firstSeenChapter,
    'lastSeenChapter': lastSeenChapter,
  };

  @override
  List<Object?> get props => [
    name,
    importance,
    firstSeenChapter,
    lastSeenChapter,
  ];
}

class EmotionalProgress extends Equatable {
  const EmotionalProgress({
    this.confidence = 0,
    this.courage = 0,
    this.serenity = 0,
    this.curiosity = 0,
  });

  final int confidence;
  final int courage;
  final int serenity;
  final int curiosity;

  factory EmotionalProgress.fromMap(Map<String, dynamic> map) =>
      EmotionalProgress(
        confidence: (map['confidence'] as num?)?.toInt() ?? 0,
        courage: (map['courage'] as num?)?.toInt() ?? 0,
        serenity: (map['serenity'] as num?)?.toInt() ?? 0,
        curiosity: (map['curiosity'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
    'confidence': confidence,
    'courage': courage,
    'serenity': serenity,
    'curiosity': curiosity,
  };

  @override
  List<Object?> get props => [confidence, courage, serenity, curiosity];
}

class MajorNarrativeEvent extends Equatable {
  const MajorNarrativeEvent({
    required this.chapter,
    required this.event,
    required this.impact,
  });

  final int chapter;
  final String event;
  final String impact;

  factory MajorNarrativeEvent.fromMap(Map<String, dynamic> map) =>
      MajorNarrativeEvent(
        chapter: (map['chapter'] as num?)?.toInt() ?? 1,
        event: map['event']?.toString() ?? '',
        impact: map['impact']?.toString() ?? '',
      );

  Map<String, dynamic> toMap() => {
    'chapter': chapter,
    'event': event,
    'impact': impact,
  };

  @override
  List<Object?> get props => [chapter, event, impact];
}
