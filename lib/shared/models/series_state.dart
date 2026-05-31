import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

String _readNarrativeText(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value.trim();
  if (value is num || value is bool) return value.toString();
  if (value is Map) {
    const preferredKeys = [
      'name',
      'title',
      'label',
      'description',
      'text',
      'value',
      'goal',
      'summary',
    ];
    for (final key in preferredKeys) {
      final text = _readNarrativeText(value[key]);
      if (text.isNotEmpty) return text;
    }
    final parts = value.values
        .map(_readNarrativeText)
        .where((text) => text.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' - ');
  }
  if (value is Iterable) {
    final parts = value
        .map(_readNarrativeText)
        .where((text) => text.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(', ');
  }
  return fallback;
}

List<String> _readNarrativeList(dynamic value) {
  if (value is! Iterable) return const [];
  return value
      .map(_readNarrativeText)
      .where((text) => text.isNotEmpty)
      .toList();
}

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
      title: _readNarrativeText(map['title']),
      goal: _readNarrativeText(map['goal']),
      emotionalStep: _readNarrativeText(map['emotionalStep']),
      newElement: _readNarrativeText(map['newElement']),
      openLoop: _readNarrativeText(map['openLoop']),
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
    List<String> readList(String key) => _readNarrativeList(map[key]);

    final rawPlan = (map['chapterPlan'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChapterPlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    return SeriesBible(
      seriesTitle: _readNarrativeText(
        map['seriesTitle'],
        fallback: 'Série du soir',
      ),
      pitch: _readNarrativeText(map['pitch']),
      universe: _readNarrativeText(map['universe']),
      tone: _readNarrativeText(map['tone']),
      mainCharacters: readList('mainCharacters'),
      secondaryCharacters: readList('secondaryCharacters'),
      recurringPlaces: readList('recurringPlaces'),
      storyArc: _readNarrativeText(map['storyArc']),
      emotionalArc: _readNarrativeText(map['emotionalArc']),
      chapterPlan: rawPlan,
      continuityRules: readList('continuityRules'),
      antiRepetitionRules: readList('antiRepetitionRules'),
      plannedEnding: _readNarrativeText(map['plannedEnding']),
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
    List<String> readList(String key) => _readNarrativeList(map[key]);

    return ChapterContinuityUpdate(
      chapterSummary: _readNarrativeText(map['chapterSummary']),
      importantEvents: readList('importantEvents'),
      charactersMet: readList('charactersMet'),
      objectsIntroduced: readList('objectsIntroduced'),
      resolvedLoops: readList('resolvedLoops'),
      openLoops: readList('openLoops'),
      emotionalStep: _readNarrativeText(map['emotionalStep']),
      thingsToRemember: readList('thingsToRemember'),
      thingsToAvoidRepeating: readList('thingsToAvoidRepeating'),
      nextChapterGoal: _readNarrativeText(map['nextChapterGoal']),
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
    required this.seriesId,
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
    required this.antiRepetitionRules,
    required this.chapterContinuityUpdates,
    required this.lastChapterSummary,
    required this.nextChapterGoal,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  final String id;
  final String seriesId;
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
  final List<String> antiRepetitionRules;
  final List<ChapterContinuityUpdate> chapterContinuityUpdates;
  final String lastChapterSummary;
  final String nextChapterGoal;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  SeriesState copyWith({
    String? id,
    String? seriesId,
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
    List<String>? antiRepetitionRules,
    List<ChapterContinuityUpdate>? chapterContinuityUpdates,
    String? lastChapterSummary,
    String? nextChapterGoal,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return SeriesState(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
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
      antiRepetitionRules: antiRepetitionRules ?? this.antiRepetitionRules,
      chapterContinuityUpdates:
          chapterContinuityUpdates ?? this.chapterContinuityUpdates,
      lastChapterSummary: lastChapterSummary ?? this.lastChapterSummary,
      nextChapterGoal: nextChapterGoal ?? this.nextChapterGoal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
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

    List<String> readList(String key) => _readNarrativeList(map[key]);

    final now = DateTime.now();
    final rawChapterPlan = (map['chapterPlan'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => ChapterPlanItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final rawContinuityUpdates =
        (map['chapterContinuityUpdates'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (e) =>
                  ChapterContinuityUpdate.fromMap(Map<String, dynamic>.from(e)),
            )
            .toList();

    return SeriesState(
      id: _readNarrativeText(map['id']),
      seriesId: _readNarrativeText(map['seriesId']).isNotEmpty
          ? _readNarrativeText(map['seriesId'])
          : 'series_${_readNarrativeText(map['childId'])}',
      childId: _readNarrativeText(map['childId']),
      userId: _readNarrativeText(map['userId']),
      status: _readNarrativeText(map['status'], fallback: 'active'),
      seriesTitle: _readNarrativeText(
        map['seriesTitle'],
        fallback: 'Série du soir',
      ),
      seriesFormat: _readNarrativeText(
        map['seriesFormat'],
        fallback: 'serialized',
      ),
      currentChapterIndex: (map['currentChapterIndex'] as num?)?.toInt() ?? 0,
      totalChapters: (map['totalChapters'] as num?)?.toInt() ?? 7,
      seriesDurationDays: (map['seriesDurationDays'] as num?)?.toInt() ?? 7,
      universe: _readNarrativeText(map['universe']),
      tone: _readNarrativeText(map['tone']),
      mainCharacters: readList('mainCharacters'),
      secondaryCharacters: readList('secondaryCharacters'),
      recurringPlaces: readList('recurringPlaces'),
      storyArc: _readNarrativeText(map['storyArc']),
      emotionalArc: _readNarrativeText(map['emotionalArc']),
      chapterPlan: rawChapterPlan,
      continuitySummary: _readNarrativeText(map['continuitySummary']),
      chapterSummaries: readList('chapterSummaries'),
      openLoops: readList('openLoops'),
      resolvedLoops: readList('resolvedLoops'),
      importantObjects: readList('importantObjects'),
      emotionalProgression: readList('emotionalProgression'),
      antiRepetitionMemory: readList('antiRepetitionMemory'),
      antiRepetitionRules: readList('antiRepetitionRules').isEmpty
          ? readList('antiRepetitionMemory')
          : readList('antiRepetitionRules'),
      chapterContinuityUpdates: rawContinuityUpdates,
      lastChapterSummary: _readNarrativeText(map['lastChapterSummary']),
      nextChapterGoal: _readNarrativeText(map['nextChapterGoal']),
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
      'seriesId': seriesId,
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
      'antiRepetitionRules': antiRepetitionRules,
      'chapterContinuityUpdates': chapterContinuityUpdates
          .map((e) => e.toMap())
          .toList(),
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
    seriesId,
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
    antiRepetitionRules,
    chapterContinuityUpdates,
    lastChapterSummary,
    nextChapterGoal,
    createdAt,
    updatedAt,
    completedAt,
  ];
}
