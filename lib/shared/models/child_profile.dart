import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums/story_format.dart';
import 'enums/story_tone.dart';
import 'enums/universe_type.dart';

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
    required this.universeType,
    required this.preferredTone,
    required this.storyFormat,
    required this.seriesDurationDays,
    required this.storyLengthMinutes,
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
  final UniverseType universeType;
  final StoryTone preferredTone;
  final StoryFormat storyFormat;
  final int seriesDurationDays;
  final int storyLengthMinutes;
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
    UniverseType? universeType,
    StoryTone? preferredTone,
    StoryFormat? storyFormat,
    int? seriesDurationDays,
    int? storyLengthMinutes,
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
      universeType: universeType ?? this.universeType,
      preferredTone: preferredTone ?? this.preferredTone,
      storyFormat: storyFormat ?? this.storyFormat,
      seriesDurationDays: seriesDurationDays ?? this.seriesDurationDays,
      storyLengthMinutes: storyLengthMinutes ?? this.storyLengthMinutes,
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
      'universeType': universeType.wireValue,
      'preferredTone': preferredTone.wireValue,
      'storyFormat': storyFormat.wireValue,
      'seriesDurationDays': seriesDurationDays,
      'storyLengthMinutes': storyLengthMinutes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChildProfile.fromMap(Map<String, dynamic> map) {
    return ChildProfile(
      id: map['id'] as String,
      userId: map['userId'] as String,
      firstName: map['firstName'] as String,
      birthMonth: (map['birthMonth'] as num).toInt(),
      birthYear: (map['birthYear'] as num).toInt(),
      preferredThemes: List<String>.from(map['preferredThemes'] as List? ?? []),
      avoidThemes: List<String>.from(map['avoidThemes'] as List? ?? []),
      personalityTraits: List<String>.from(
        map['personalityTraits'] as List? ?? [],
      ),
      fearsToAddress: List<String>.from(map['fearsToAddress'] as List? ?? []),
      valuesToTeach: List<String>.from(map['valuesToTeach'] as List? ?? []),
      universeType: UniverseTypeX.parse(map['universeType'] as String?),
      preferredTone: StoryToneX.parse(map['preferredTone'] as String?),
      storyFormat: StoryFormatFirestore.parse(map['storyFormat'] as String?),
      seriesDurationDays: (map['seriesDurationDays'] as num).toInt(),
      storyLengthMinutes: (map['storyLengthMinutes'] as num).toInt(),
      createdAt: _readDate(map['createdAt']),
      updatedAt: _readDate(map['updatedAt']),
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
    universeType,
    preferredTone,
    storyFormat,
    seriesDurationDays,
    storyLengthMinutes,
    createdAt,
    updatedAt,
  ];
}
