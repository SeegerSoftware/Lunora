import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ChapterPlanItem extends Equatable {
  const ChapterPlanItem({
    required this.chapterIndex,
    required this.title,
    required this.goal,
    required this.emotionalStep,
    required this.newElement,
    required this.openLoop,
  });

  final int chapterIndex;
  final String title;
  final String goal;
  final String emotionalStep;
  final String newElement;
  final String openLoop;

  factory ChapterPlanItem.fromMap(Map<String, dynamic> map) {
    return ChapterPlanItem(
      chapterIndex: (map['chapterIndex'] as num?)?.toInt() ?? 1,
      title: (map['title'] as String?)?.trim() ?? '',
      goal: (map['goal'] as String?)?.trim() ?? '',
      emotionalStep: (map['emotionalStep'] as String?)?.trim() ?? '',
      newElement: (map['newElement'] as String?)?.trim() ?? '',
      openLoop: (map['openLoop'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterIndex': chapterIndex,
      'title': title,
      'goal': goal,
      'emotionalStep': emotionalStep,
      'newElement': newElement,
      'openLoop': openLoop,
    };
  }

  @override
  List<Object?> get props => [
    chapterIndex,
    title,
    goal,
    emotionalStep,
    newElement,
    openLoop,
  ];
}

class SeriesBible extends Equatable {
  const SeriesBible({
    required this.seriesTitle,
    required this.pitch,
    required this.universe,
    required this.tone,
    required this.mainCharacters,
    required this.secondaryCharacters,
    required this.recurringPlaces,
    required this.storyArc,
    required this.emotionalArc,
    required this.chapterPlan,
    required this.continuityRules,
    required this.antiRepetitionRules,
    required this.plannedEnding,
  });

  final String seriesTitle;
  final String pitch;
  final String universe;
  final String tone;
  final List<String> mainCharacters;
  final List<String> secondaryCharacters;
  final List<String> recurringPlaces;
  final String storyArc;
  final String emotionalArc;
  final List<ChapterPlanItem> chapterPlan;
  final List<String> continuityRules;
  final List<String> antiRepetitionRules;
  final String plannedEnding;

  factory SeriesBible.fromMap(Map<String, dynamic> map) {
    List<String> readList(String key) =>
        List<String>.from(map[key] as List? ?? const [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final rawPlan = (map['chapterPlan'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChapterPlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return SeriesBible(
      seriesTitle: (map['seriesTitle'] as String?)?.trim() ?? 'Série du soir',
      pitch: (map['pitch'] as String?)?.trim() ?? '',
      universe: (map['universe'] as String?)?.trim() ?? '',
      tone: (map['tone'] as String?)?.trim() ?? '',
      mainCharacters: readList('mainCharacters'),
      secondaryCharacters: readList('secondaryCharacters'),
      recurringPlaces: readList('recurringPlaces'),
      storyArc: (map['storyArc'] as String?)?.trim() ?? '',
      emotionalArc: (map['emotionalArc'] as String?)?.trim() ?? '',
      chapterPlan: rawPlan,
      continuityRules: readList('continuityRules'),
      antiRepetitionRules: readList('antiRepetitionRules'),
      plannedEnding: (map['plannedEnding'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seriesTitle': seriesTitle,
      'pitch': pitch,
      'universe': universe,
      'tone': tone,
      'mainCharacters': mainCharacters,
      'secondaryCharacters': secondaryCharacters,
      'recurringPlaces': recurringPlaces,
      'storyArc': storyArc,
      'emotionalArc': emotionalArc,
      'chapterPlan': chapterPlan.map((e) => e.toMap()).toList(),
      'continuityRules': continuityRules,
      'antiRepetitionRules': antiRepetitionRules,
      'plannedEnding': plannedEnding,
    };
  }

  @override
  List<Object?> get props => [
    seriesTitle,
    pitch,
    universe,
    tone,
    mainCharacters,
    secondaryCharacters,
    recurringPlaces,
    storyArc,
    emotionalArc,
    chapterPlan,
    continuityRules,
    antiRepetitionRules,
    plannedEnding,
  ];
}

class ChapterContinuityUpdate extends Equatable {
  const ChapterContinuityUpdate({
    required this.chapterSummary,
    required this.importantEvents,
    required this.charactersMet,
    required this.objectsIntroduced,
    required this.resolvedLoops,
    required this.openLoops,
    required this.emotionalStep,
    required this.thingsToRemember,
    required this.thingsToAvoidRepeating,
    required this.nextChapterGoal,
  });

  final String chapterSummary;
  final List<String> importantEvents;
  final List<String> charactersMet;
  final List<String> objectsIntroduced;
  final List<String> resolvedLoops;
  final List<String> openLoops;
  final String emotionalStep;
  final List<String> thingsToRemember;
  final List<String> thingsToAvoidRepeating;
  final String nextChapterGoal;

  factory ChapterContinuityUpdate.fromMap(Map<String, dynamic> map) {
    List<String> readList(String key) =>
        List<String>.from(map[key] as List? ?? const [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    return ChapterContinuityUpdate(
      chapterSummary: (map['chapterSummary'] as String?)?.trim() ?? '',
      importantEvents: readList('importantEvents'),
      charactersMet: readList('charactersMet'),
      objectsIntroduced: readList('objectsIntroduced'),
      resolvedLoops: readList('resolvedLoops'),
      openLoops: readList('openLoops'),
      emotionalStep: (map['emotionalStep'] as String?)?.trim() ?? '',
      thingsToRemember: readList('thingsToRemember'),
      thingsToAvoidRepeating: readList('thingsToAvoidRepeating'),
      nextChapterGoal: (map['nextChapterGoal'] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterSummary': chapterSummary,
      'importantEvents': importantEvents,
      'charactersMet': charactersMet,
      'objectsIntroduced': objectsIntroduced,
      'resolvedLoops': resolvedLoops,
      'openLoops': openLoops,
      'emotionalStep': emotionalStep,
      'thingsToRemember': thingsToRemember,
      'thingsToAvoidRepeating': thingsToAvoidRepeating,
      'nextChapterGoal': nextChapterGoal,
    };
  }

  @override
  List<Object?> get props => [
    chapterSummary,
    importantEvents,
    charactersMet,
    objectsIntroduced,
    resolvedLoops,
    openLoops,
    emotionalStep,
    thingsToRemember,
    thingsToAvoidRepeating,
    nextChapterGoal,
  ];
}

class SeriesState extends Equatable {
  const SeriesState({
    required this.id,
    required this.childId,
    required this.userId,
    required this.status,
    required this.seriesTitle,
    required this.seriesFormat,
    required this.currentChapterIndex,
    required this.totalChapters,
    required this.seriesDurationDays,
    required this.universe,
    required this.tone,
    required this.mainCharacters,
    required this.secondaryCharacters,
    required this.recurringPlaces,
    required this.storyArc,
    required this.emotionalArc,
    required this.chapterPlan,
    required this.continuitySummary,
    required this.chapterSummaries,
    required this.openLoops,
    required this.resolvedLoops,
    required this.importantObjects,
    required this.emotionalProgression,
    required this.antiRepetitionMemory,
    required this.lastChapterSummary,
    required this.nextChapterGoal,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String childId;
  final String userId;
  final String status;
  final String seriesTitle;
  final String seriesFormat;
  final int currentChapterIndex;
  final int totalChapters;
  final int seriesDurationDays;
  final String universe;
  final String tone;
  final List<String> mainCharacters;
  final List<String> secondaryCharacters;
  final List<String> recurringPlaces;
  final String storyArc;
  final String emotionalArc;
  final List<ChapterPlanItem> chapterPlan;
  final String continuitySummary;
  final List<String> chapterSummaries;
  final List<String> openLoops;
  final List<String> resolvedLoops;
  final List<String> importantObjects;
  final List<String> emotionalProgression;
  final List<String> antiRepetitionMemory;
  final String lastChapterSummary;
  final String nextChapterGoal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  SeriesState copyWith({
    String? id,
    String? childId,
    String? userId,
    String? status,
    String? seriesTitle,
    String? seriesFormat,
    int? currentChapterIndex,
    int? totalChapters,
    int? seriesDurationDays,
    String? universe,
    String? tone,
    List<String>? mainCharacters,
    List<String>? secondaryCharacters,
    List<String>? recurringPlaces,
    String? storyArc,
    String? emotionalArc,
    List<ChapterPlanItem>? chapterPlan,
    String? continuitySummary,
    List<String>? chapterSummaries,
    List<String>? openLoops,
    List<String>? resolvedLoops,
    List<String>? importantObjects,
    List<String>? emotionalProgression,
    List<String>? antiRepetitionMemory,
    String? lastChapterSummary,
    String? nextChapterGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return SeriesState(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      seriesFormat: seriesFormat ?? this.seriesFormat,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      totalChapters: totalChapters ?? this.totalChapters,
      seriesDurationDays: seriesDurationDays ?? this.seriesDurationDays,
      universe: universe ?? this.universe,
      tone: tone ?? this.tone,
      mainCharacters: mainCharacters ?? this.mainCharacters,
      secondaryCharacters: secondaryCharacters ?? this.secondaryCharacters,
      recurringPlaces: recurringPlaces ?? this.recurringPlaces,
      storyArc: storyArc ?? this.storyArc,
      emotionalArc: emotionalArc ?? this.emotionalArc,
      chapterPlan: chapterPlan ?? this.chapterPlan,
      continuitySummary: continuitySummary ?? this.continuitySummary,
      chapterSummaries: chapterSummaries ?? this.chapterSummaries,
      openLoops: openLoops ?? this.openLoops,
      resolvedLoops: resolvedLoops ?? this.resolvedLoops,
      importantObjects: importantObjects ?? this.importantObjects,
      emotionalProgression: emotionalProgression ?? this.emotionalProgression,
      antiRepetitionMemory: antiRepetitionMemory ?? this.antiRepetitionMemory,
      lastChapterSummary: lastChapterSummary ?? this.lastChapterSummary,
      nextChapterGoal: nextChapterGoal ?? this.nextChapterGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory SeriesState.fromMap(Map<String, dynamic> map) {
    DateTime readDate(dynamic value, DateTime fallback) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value) ?? fallback;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return fallback;
    }

    List<String> readList(String key) =>
        List<String>.from(map[key] as List? ?? const [])
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

    final now = DateTime.now();
    final rawChapterPlan = (map['chapterPlan'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChapterPlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return SeriesState(
      id: (map['id'] as String?)?.trim() ?? '',
      childId: (map['childId'] as String?)?.trim() ?? '',
      userId: (map['userId'] as String?)?.trim() ?? '',
      status: (map['status'] as String?)?.trim() ?? 'active',
      seriesTitle: (map['seriesTitle'] as String?)?.trim() ?? 'Série du soir',
      seriesFormat: (map['seriesFormat'] as String?)?.trim() ?? 'serialized',
      currentChapterIndex: (map['currentChapterIndex'] as num?)?.toInt() ?? 0,
      totalChapters: (map['totalChapters'] as num?)?.toInt() ?? 7,
      seriesDurationDays: (map['seriesDurationDays'] as num?)?.toInt() ?? 7,
      universe: (map['universe'] as String?)?.trim() ?? '',
      tone: (map['tone'] as String?)?.trim() ?? '',
      mainCharacters: readList('mainCharacters'),
      secondaryCharacters: readList('secondaryCharacters'),
      recurringPlaces: readList('recurringPlaces'),
      storyArc: (map['storyArc'] as String?)?.trim() ?? '',
      emotionalArc: (map['emotionalArc'] as String?)?.trim() ?? '',
      chapterPlan: rawChapterPlan,
      continuitySummary: (map['continuitySummary'] as String?)?.trim() ?? '',
      chapterSummaries: readList('chapterSummaries'),
      openLoops: readList('openLoops'),
      resolvedLoops: readList('resolvedLoops'),
      importantObjects: readList('importantObjects'),
      emotionalProgression: readList('emotionalProgression'),
      antiRepetitionMemory: readList('antiRepetitionMemory'),
      lastChapterSummary: (map['lastChapterSummary'] as String?)?.trim() ?? '',
      nextChapterGoal: (map['nextChapterGoal'] as String?)?.trim() ?? '',
      createdAt: readDate(map['createdAt'], now),
      updatedAt: readDate(map['updatedAt'], now),
      completedAt: map['completedAt'] == null
          ? null
          : readDate(map['completedAt'], now),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'status': status,
      'seriesTitle': seriesTitle,
      'seriesFormat': seriesFormat,
      'currentChapterIndex': currentChapterIndex,
      'totalChapters': totalChapters,
      'seriesDurationDays': seriesDurationDays,
      'universe': universe,
      'tone': tone,
      'mainCharacters': mainCharacters,
      'secondaryCharacters': secondaryCharacters,
      'recurringPlaces': recurringPlaces,
      'storyArc': storyArc,
      'emotionalArc': emotionalArc,
      'chapterPlan': chapterPlan.map((e) => e.toMap()).toList(),
      'continuitySummary': continuitySummary,
      'chapterSummaries': chapterSummaries,
      'openLoops': openLoops,
      'resolvedLoops': resolvedLoops,
      'importantObjects': importantObjects,
      'emotionalProgression': emotionalProgression,
      'antiRepetitionMemory': antiRepetitionMemory,
      'lastChapterSummary': lastChapterSummary,
      'nextChapterGoal': nextChapterGoal,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    id,
    childId,
    userId,
    status,
    seriesTitle,
    seriesFormat,
    currentChapterIndex,
    totalChapters,
    seriesDurationDays,
    universe,
    tone,
    mainCharacters,
    secondaryCharacters,
    recurringPlaces,
    storyArc,
    emotionalArc,
    chapterPlan,
    continuitySummary,
    chapterSummaries,
    openLoops,
    resolvedLoops,
    importantObjects,
    emotionalProgression,
    antiRepetitionMemory,
    lastChapterSummary,
    nextChapterGoal,
    createdAt,
    updatedAt,
    completedAt,
  ];
}
