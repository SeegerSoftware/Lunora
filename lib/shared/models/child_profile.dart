import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums/story_format.dart';
import 'enums/story_tone.dart';
import 'story_universe.dart';

class ChildProfile extends Equatable {
  const ChildProfile({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.birthMonth,
    required this.birthYear,
    required this.preferredThemes,
    required this.avoidThemes,
    required this.personalityTraits,
    required this.fearsToAddress,
    required this.valuesToTeach,
    required this.storyUniverse,
    required this.preferredTone,
    required this.storyFormat,
    required this.seriesDurationDays,
    required this.storyLengthMinutes,
    this.language = 'fr',
    this.readingDurationMinutes,
    this.preferredUniverse = '',
    this.magicLevel = 'legerement magique',
    this.adventureIntensity = 'equilibree',
    this.softenedFears = const [],
    this.valuesToTransmit = const [],
    this.bedtimeEnergyLevel = 'calme',
    this.familiarElements = const [],
    this.tonightGoal = 's’endormir calmement',
    this.extraStoryHints = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String firstName;
  final int birthMonth;
  final int birthYear;
  final List<String> preferredThemes;
  final List<String> avoidThemes;
  final List<String> personalityTraits;
  final List<String> fearsToAddress;
  final List<String> valuesToTeach;
  /// Univers narratif principal (clé Firestore historique : `universeType`).
  final StoryUniverse storyUniverse;
  final StoryTone preferredTone;
  final StoryFormat storyFormat;
  final int seriesDurationDays;
  final int storyLengthMinutes;
  final String language;
  final int? readingDurationMinutes;
  final String preferredUniverse;
  final String magicLevel;
  final String adventureIntensity;
  final List<String> softenedFears;
  final List<String> valuesToTransmit;
  final String bedtimeEnergyLevel;
  final List<String> familiarElements;
  final String tonightGoal;
  /// Texte libre du parent (souhaits, limites, contexte) transmis au LLM.
  final String extraStoryHints;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChildProfile copyWith({
    String? id,
    String? userId,
    String? firstName,
    int? birthMonth,
    int? birthYear,
    List<String>? preferredThemes,
    List<String>? avoidThemes,
    List<String>? personalityTraits,
    List<String>? fearsToAddress,
    List<String>? valuesToTeach,
    StoryUniverse? storyUniverse,
    StoryTone? preferredTone,
    StoryFormat? storyFormat,
    int? seriesDurationDays,
    int? storyLengthMinutes,
    String? language,
    int? readingDurationMinutes,
    String? preferredUniverse,
    String? magicLevel,
    String? adventureIntensity,
    List<String>? softenedFears,
    List<String>? valuesToTransmit,
    String? bedtimeEnergyLevel,
    List<String>? familiarElements,
    String? tonightGoal,
    String? extraStoryHints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      birthMonth: birthMonth ?? this.birthMonth,
      birthYear: birthYear ?? this.birthYear,
      preferredThemes: preferredThemes ?? this.preferredThemes,
      avoidThemes: avoidThemes ?? this.avoidThemes,
      personalityTraits: personalityTraits ?? this.personalityTraits,
      fearsToAddress: fearsToAddress ?? this.fearsToAddress,
      valuesToTeach: valuesToTeach ?? this.valuesToTeach,
      storyUniverse: storyUniverse ?? this.storyUniverse,
      preferredTone: preferredTone ?? this.preferredTone,
      storyFormat: storyFormat ?? this.storyFormat,
      seriesDurationDays: seriesDurationDays ?? this.seriesDurationDays,
      storyLengthMinutes: storyLengthMinutes ?? this.storyLengthMinutes,
      language: language ?? this.language,
      readingDurationMinutes: readingDurationMinutes ?? this.readingDurationMinutes,
      preferredUniverse: preferredUniverse ?? this.preferredUniverse,
      magicLevel: magicLevel ?? this.magicLevel,
      adventureIntensity: adventureIntensity ?? this.adventureIntensity,
      softenedFears: softenedFears ?? this.softenedFears,
      valuesToTransmit: valuesToTransmit ?? this.valuesToTransmit,
      bedtimeEnergyLevel: bedtimeEnergyLevel ?? this.bedtimeEnergyLevel,
      familiarElements: familiarElements ?? this.familiarElements,
      tonightGoal: tonightGoal ?? this.tonightGoal,
      extraStoryHints: extraStoryHints ?? this.extraStoryHints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'birthMonth': birthMonth,
      'birthYear': birthYear,
      'preferredThemes': preferredThemes,
      'avoidThemes': avoidThemes,
      'personalityTraits': personalityTraits,
      'fearsToAddress': fearsToAddress,
      'valuesToTeach': valuesToTeach,
      'universeType': storyUniverse.wireValue,
      'preferredTone': preferredTone.wireValue,
      'storyFormat': storyFormat.wireValue,
      'seriesDurationDays': seriesDurationDays,
      'storyLengthMinutes': storyLengthMinutes,
      'readingDurationMinutes': readingDurationMinutes ?? storyLengthMinutes,
      'language': language,
      'preferredUniverse': preferredUniverse,
      'magicLevel': magicLevel,
      'adventureIntensity': adventureIntensity,
      'favoriteThemes': preferredThemes,
      'softenedFears': softenedFears.isEmpty ? fearsToAddress : softenedFears,
      'valuesToTransmit': valuesToTransmit.isEmpty ? valuesToTeach : valuesToTransmit,
      'bedtimeEnergyLevel': bedtimeEnergyLevel,
      'familiarElements': familiarElements,
      'tonightGoal': tonightGoal,
      'extraStoryHints': extraStoryHints,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    List<String> readList(String key, {List<String>? fallback}) {
      final raw = map[key];
      if (raw is List) {
        return List<String>.from(raw).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return fallback ?? const [];
    }

    String readString(String key, {String fallback = ''}) {
      final raw = map[key];
      if (raw == null) return fallback;
      return raw.toString().trim();
    }

    final legacyPreferredThemes = readList('preferredThemes');
    final favoriteThemes = readList('favoriteThemes', fallback: legacyPreferredThemes);
    final legacyFears = readList('fearsToAddress');
    final softenedFears = readList('softenedFears', fallback: legacyFears);
    final legacyValues = readList('valuesToTeach');
    final valuesToTransmit = readList('valuesToTransmit', fallback: legacyValues);
    final rawStoryLength = (map['storyLengthMinutes'] as num?)?.toInt();
    final rawReadingDuration = (map['readingDurationMinutes'] as num?)?.toInt();

    return ChildProfile(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      birthMonth: (map['birthMonth'] as num?)?.toInt() ?? 6,
      birthYear: (map['birthYear'] as num?)?.toInt() ?? DateTime.now().year - 5,
      preferredThemes: favoriteThemes,
      avoidThemes: readList('avoidThemes'),
      personalityTraits: readList('personalityTraits'),
      fearsToAddress: softenedFears,
      valuesToTeach: valuesToTransmit,
      storyUniverse: StoryUniverseX.parse(map['universeType'] as String?),
      preferredTone: StoryToneX.parse(map['preferredTone'] as String?),
      storyFormat: StoryFormatFirestore.parse(map['storyFormat'] as String?),
      seriesDurationDays: (map['seriesDurationDays'] as num?)?.toInt() ?? 0,
      storyLengthMinutes: rawStoryLength ?? rawReadingDuration ?? 10,
      readingDurationMinutes: rawReadingDuration,
      language: readString('language', fallback: 'fr'),
      preferredUniverse: readString(
        'preferredUniverse',
        fallback: StoryUniverseX.parse(map['universeType'] as String?).displayName,
      ),
      magicLevel: readString('magicLevel', fallback: 'legerement magique'),
      adventureIntensity: readString('adventureIntensity', fallback: 'equilibree'),
      softenedFears: softenedFears,
      valuesToTransmit: valuesToTransmit,
      bedtimeEnergyLevel: readString('bedtimeEnergyLevel', fallback: 'calme'),
      familiarElements: readList('familiarElements'),
      tonightGoal: readString('tonightGoal', fallback: 's’endormir calmement'),
      extraStoryHints: readString('extraStoryHints'),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    throw FormatException('Unsupported date: $value');
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    firstName,
    birthMonth,
    birthYear,
    preferredThemes,
    avoidThemes,
    personalityTraits,
    fearsToAddress,
    valuesToTeach,
    storyUniverse,
    preferredTone,
    storyFormat,
    seriesDurationDays,
    storyLengthMinutes,
    language,
    readingDurationMinutes,
    preferredUniverse,
    magicLevel,
    adventureIntensity,
    softenedFears,
    valuesToTransmit,
    bedtimeEnergyLevel,
    familiarElements,
    tonightGoal,
    extraStoryHints,
    createdAt,
    updatedAt,
  ];
}
