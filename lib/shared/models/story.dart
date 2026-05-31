import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'enums/story_format.dart';
import 'enums/story_tone.dart';

class Story extends Equatable {
  const Story({
    required this.id,
    required this.childId,
    required this.userId,
    required this.dateKey,
    required this.title,
    required this.content,
    required this.summary,
    required this.theme,
    required this.tone,
    required this.estimatedReadingMinutes,
    required this.format,
    required this.chapterNumber,
    required this.totalChapters,
    this.seriesId,
    this.generationSource = 'unknown',
    required this.createdAt,
    this.qualityScore = 0,
    this.qualityDetails = const {},
    this.qualityWarnings = const [],
    this.coverImageUrl,
    this.coverImageStatus = 'pending',
    this.coverPrompt,
    this.audioStatus = 'unavailable',
    this.audioUrl,
    this.audioVoice,
    this.audioDuration,
    this.userFeedback,
    this.userFeedbackAt,
  });

  final String id;
  final String childId;
  final String userId;
  final String dateKey;
  final String title;
  final String content;
  final String summary;
  final String theme;
  final StoryTone tone;
  final int estimatedReadingMinutes;
  final StoryFormat format;
  final int chapterNumber;
  final int totalChapters;
  final String? seriesId;
  final String generationSource;
  final DateTime createdAt;
  final int qualityScore;
  final Map<String, int> qualityDetails;
  final List<String> qualityWarnings;
  final String? coverImageUrl;
  final String coverImageStatus;
  final String? coverPrompt;
  final String audioStatus;
  final String? audioUrl;
  final String? audioVoice;
  final int? audioDuration;

  /// 1 = j’aime, -1 = je n’aime pas, null = pas encore d’avis.
  final int? userFeedback;
  final DateTime? userFeedbackAt;

  bool get isSerialized => format == StoryFormat.serializedChapters;

  Story copyWith({
    String? id,
    String? childId,
    String? userId,
    String? dateKey,
    String? title,
    String? content,
    String? summary,
    String? theme,
    StoryTone? tone,
    int? estimatedReadingMinutes,
    StoryFormat? format,
    int? chapterNumber,
    int? totalChapters,
    String? seriesId,
    String? generationSource,
    DateTime? createdAt,
    int? qualityScore,
    Map<String, int>? qualityDetails,
    List<String>? qualityWarnings,
    String? coverImageUrl,
    String? coverImageStatus,
    String? coverPrompt,
    String? audioStatus,
    String? audioUrl,
    String? audioVoice,
    int? audioDuration,
    int? userFeedback,
    DateTime? userFeedbackAt,
  }) {
    return Story(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      theme: theme ?? this.theme,
      tone: tone ?? this.tone,
      estimatedReadingMinutes:
          estimatedReadingMinutes ?? this.estimatedReadingMinutes,
      format: format ?? this.format,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      totalChapters: totalChapters ?? this.totalChapters,
      seriesId: seriesId ?? this.seriesId,
      generationSource: generationSource ?? this.generationSource,
      createdAt: createdAt ?? this.createdAt,
      qualityScore: qualityScore ?? this.qualityScore,
      qualityDetails: qualityDetails ?? this.qualityDetails,
      qualityWarnings: qualityWarnings ?? this.qualityWarnings,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImageStatus: coverImageStatus ?? this.coverImageStatus,
      coverPrompt: coverPrompt ?? this.coverPrompt,
      audioStatus: audioStatus ?? this.audioStatus,
      audioUrl: audioUrl ?? this.audioUrl,
      audioVoice: audioVoice ?? this.audioVoice,
      audioDuration: audioDuration ?? this.audioDuration,
      userFeedback: userFeedback ?? this.userFeedback,
      userFeedbackAt: userFeedbackAt ?? this.userFeedbackAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'childId': childId,
      'userId': userId,
      'dateKey': dateKey,
      'title': title,
      'content': content,
      'summary': summary,
      'theme': theme,
      'tone': tone.wireValue,
      'estimatedReadingMinutes': estimatedReadingMinutes,
      'format': format.wireValue,
      'chapterNumber': chapterNumber,
      'totalChapters': totalChapters,
      'seriesId': seriesId,
      'generationSource': generationSource,
      'createdAt': createdAt.toIso8601String(),
      'qualityScore': qualityScore,
      'qualityDetails': qualityDetails,
      'qualityWarnings': qualityWarnings,
      'coverImageUrl': coverImageUrl,
      'coverImageStatus': coverImageStatus,
      'coverPrompt': coverPrompt,
      'audioStatus': audioStatus,
      'audioUrl': audioUrl,
      'audioVoice': audioVoice,
      'audioDuration': audioDuration,
      if (userFeedback != null) 'userFeedback': userFeedback,
      if (userFeedbackAt != null)
        'userFeedbackAt': userFeedbackAt!.toIso8601String(),
    };
  }

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'] as String,
      childId: map['childId'] as String,
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      summary: map['summary'] as String,
      theme: map['theme'] as String,
      tone: StoryToneX.parse(map['tone'] as String?),
      estimatedReadingMinutes: (map['estimatedReadingMinutes'] as num).toInt(),
      format: StoryFormatFirestore.parse(map['format'] as String?),
      chapterNumber: (map['chapterNumber'] as num).toInt(),
      totalChapters: (map['totalChapters'] as num).toInt(),
      seriesId: map['seriesId'] as String?,
      generationSource: (map['generationSource'] as String?) ?? 'unknown',
      createdAt: _readDate(map['createdAt']),
      qualityScore: (map['qualityScore'] as num?)?.toInt() ?? 0,
      qualityDetails: _readIntMap(map['qualityDetails']),
      qualityWarnings: _readStringList(map['qualityWarnings']),
      coverImageUrl: map['coverImageUrl'] as String?,
      coverImageStatus: (map['coverImageStatus'] as String?) ?? 'pending',
      coverPrompt: map['coverPrompt'] as String?,
      audioStatus: (map['audioStatus'] as String?) ?? 'unavailable',
      audioUrl: map['audioUrl'] as String?,
      audioVoice: map['audioVoice'] as String?,
      audioDuration: (map['audioDuration'] as num?)?.toInt(),
      userFeedback: (map['userFeedback'] as num?)?.toInt(),
      userFeedbackAt: _readDateNullable(map['userFeedbackAt']),
    );
  }

  static DateTime? _readDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static Map<String, int> _readIntMap(dynamic value) {
    if (value is! Map) return const {};
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num?)?.toInt() ?? 0),
    );
  }

  static List<String> _readStringList(dynamic value) {
    if (value is! Iterable) return const [];
    return value.map((item) => item.toString()).toList();
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
    childId,
    userId,
    dateKey,
    title,
    content,
    summary,
    theme,
    tone,
    estimatedReadingMinutes,
    format,
    chapterNumber,
    totalChapters,
    seriesId,
    generationSource,
    createdAt,
    qualityScore,
    qualityDetails,
    qualityWarnings,
    coverImageUrl,
    coverImageStatus,
    coverPrompt,
    audioStatus,
    audioUrl,
    audioVoice,
    audioDuration,
    userFeedback,
    userFeedbackAt,
  ];
}
